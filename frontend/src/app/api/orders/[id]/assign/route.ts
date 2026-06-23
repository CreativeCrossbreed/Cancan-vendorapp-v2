import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import { notifyOrderAccepted } from '@/lib/whatsapp-notifications';

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    if (admin.role !== 'super_admin') {
        return Response.json({ error: 'Only super admins can assign orders' }, { status: 403 });
    }

    const { id } = await params;
    const { vendor_id } = await req.json();

    if (!vendor_id) {
        return Response.json({ error: 'Vendor ID is required' }, { status: 400 });
    }

    const { data: selectedVendor } = await supabaseAdmin
        .from('vendors')
        .select('name, business_name')
        .eq('id', vendor_id)
        .maybeSingle();

    const { data: existingOrder } = await supabaseAdmin
        .from('orders')
        .select('id, order_number, customer:customers(phone)')
        .eq('id', id)
        .maybeSingle();

    const { data: order, error } = await supabaseAdmin
        .from('orders')
        .update({ vendor_id, status: 'assigned' })
        .eq('id', id)
        .select()
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const customerPhone = (existingOrder as any)?.customer?.phone as string | undefined;
    const vendorName =
        (selectedVendor?.name as string | undefined) ||
        (selectedVendor?.business_name as string | undefined) ||
        'your vendor';
    const orderRef = (existingOrder as any)?.order_number || id;

    if (customerPhone) {
        try {
            await notifyOrderAccepted(customerPhone, orderRef, vendorName);
        } catch (notificationError) {
            console.error('[PUT /api/orders/:id/assign] notification failed', notificationError);
        }
    }

    return Response.json(order);
}
