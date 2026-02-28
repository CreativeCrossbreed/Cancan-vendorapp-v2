import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { sendWhatsAppMessage } from '@/lib/whatsapp';

export async function POST(req: NextRequest) {
    try {
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
            city,
            state,
            pincode,
        } = body;

        // Validate required fields
        if (!phone || !name || !address || !vendorId) {
            return Response.json(
                { error: 'Missing required fields: phone, name, address, vendorId' },
                { status: 400 }
            );
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

        // Upsert customer (insert if new, update if exists by phone)
        const { data: customer, error: customerError } = await supabaseAdmin
            .from('customers')
            .upsert(
                {
                    phone,
                    name,
                    address,
                    flat_number: flatNumber || null,
                    floor: floor || null,
                    building_name: buildingName || null,
                    landmark: landmark || null,
                    latitude: latitude || null,
                    longitude: longitude || null,
                    city: city || null,
                    state: state || null,
                    pincode: pincode || null,
                    is_verified: true,
                    verification_status: 'verified',
                },
                { onConflict: 'phone' }
            )
            .select()
            .single();

        if (customerError) {
            console.error('Customer upsert error:', customerError);
            return Response.json(
                { error: 'Failed to save customer details' },
                { status: 500 }
            );
        }

        // Link customer to vendor (ignore if already linked)
        await supabaseAdmin
            .from('customer_vendors')
            .upsert(
                {
                    customer_id: customer.id,
                    vendor_id: vendorId,
                    referral_source: 'qr_code',
                },
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
