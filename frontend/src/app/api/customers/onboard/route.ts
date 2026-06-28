import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { sendWhatsAppMessage } from '@/lib/whatsapp';
import { isRateLimited } from '@/lib/rate-limit';

export async function POST(req: NextRequest) {
    try {
        const ip = req.headers.get('x-forwarded-for') || 'unknown';
        if (isRateLimited(`onboard:${ip}`, 20, 60 * 60 * 1000)) {
            return Response.json({ error: 'Too many requests. Try again later.' }, { status: 429 });
        }

        const body = await req.json();
        const {
            phone,
            vendorId,
            name,
            address,
            flatNumber,
            floor,
            buildingName,
            landmark,
            latitude,
            longitude,
        } = body;

        // Validate required fields
        if (!phone || !name || !address || !vendorId) {
            return Response.json(
                { error: 'Missing required fields: phone, name, address, vendorId' },
                { status: 400 }
            );
        }

        if (isRateLimited(`onboard:phone:${phone}`, 5, 60 * 60 * 1000)) {
            return Response.json({ error: 'Too many requests for this phone number. Try again later.' }, { status: 429 });
        }

        // Validate vendor exists
        const { data: vendor, error: vendorError } = await supabaseAdmin
            .from('vendors')
            .select('id, business_name')
            .eq('id', vendorId)
            .single();

        if (vendorError || !vendor) {
            return Response.json({ error: 'Vendor not found' }, { status: 404 });
        }

        // Model A: a customer is owned by exactly one vendor at a time
        // (customers.vendor_id). Lookup is by phone GLOBALLY, not scoped to
        // this vendor — a phone number identifies one customer identity,
        // who may currently belong to a different vendor. Scanning a new
        // vendor's QR code is treated as an explicit request to switch —
        // we move the existing row (update vendor_id) rather than creating
        // a second row for the same person. Do NOT let an unauthenticated
        // POST overwrite their existing name/address though (anyone who
        // guesses/knows a phone number could otherwise corrupt a real
        // customer's profile) — only vendor_id changes on reassignment.
        const { data: existingCustomer } = await supabaseAdmin
            .from('customers')
            .select('*')
            .eq('phone', phone)
            .maybeSingle();

        let customer = existingCustomer;
        let customerError: { message: string } | null = null;

        if (!existingCustomer) {
            const inserted = await supabaseAdmin
                .from('customers')
                .insert({
                    vendor_id: vendorId,
                    phone,
                    name,
                    address,
                    flat_number: flatNumber || null,
                    floor: floor || null,
                    building_name: buildingName || null,
                    landmark: landmark || null,
                    latitude: latitude || null,
                    longitude: longitude || null,
                    is_verified: true,
                })
                .select()
                .single();
            customer = inserted.data;
            customerError = inserted.error;
        } else if (existingCustomer.vendor_id !== vendorId) {
            const { data: reassigned, error: reassignError } = await supabaseAdmin
                .from('customers')
                .update({ vendor_id: vendorId })
                .eq('id', existingCustomer.id)
                .select()
                .single();
            customer = reassigned;
            customerError = reassignError;
        }

        if (customerError || !customer) {
            console.error('Customer upsert error:', customerError);
            return Response.json(
                { error: 'Failed to save customer details' },
                { status: 500 }
            );
        }

        // Also record the relationship in customer_vendors for any code that
        // still reads the historical multi-vendor linking table.
        await supabaseAdmin
            .from('customer_vendors')
            .upsert(
                { customer_id: customer.id, vendor_id: vendorId },
                { onConflict: 'customer_id,vendor_id' }
            );

        // Send WhatsApp confirmation to the customer
        try {
            await sendWhatsAppMessage(
                phone,
                `✅ Welcome to Can Can, ${name}! You're now connected with ${vendor.business_name}.\n\nSend "order" anytime to place a new water can order. 🚰`
            );
        } catch (whatsappError) {
            // Don't fail the onboarding if WhatsApp message fails
            console.warn('WhatsApp confirmation failed:', whatsappError);
        }

        return Response.json({
            success: true,
            message: 'Customer onboarded successfully',
            customer: {
                id: customer.id,
                name: customer.name,
                phone: customer.phone,
            },
            vendor: {
                id: vendor.id,
                businessName: vendor.business_name,
            },
        });
    } catch (error) {
        console.error('Onboarding error:', error);
        return Response.json(
            { error: 'Internal server error' },
            { status: 500 }
        );
    }
}
