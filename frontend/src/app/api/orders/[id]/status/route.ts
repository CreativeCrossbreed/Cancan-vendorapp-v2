import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';
import {
    notifyDeliveryFailed,
    notifyOrderDelivered,
} from '@/lib/whatsapp-notifications';

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;
    const { status, notes, cancellation_reason } = await req.json();

    if (!status) {
        return Response.json({ error: 'Status is required' }, { status: 400 });
    }

    const { data: existingOrder } = await supabaseAdmin
        .from('orders')
        .select(
            'id, order_number, delivery_date, delivered_at, is_delivered, customer:customers(phone), vendor:vendors(name, business_name)',
        )
        .eq('id', id)
        .maybeSingle();

    const markDelivered = status === 'delivered' || status === 'completed';
    const updatePayload: Record<string, unknown> = {
        status,
        notes,
        cancellation_reason,
        is_delivered: markDelivered ? true : (existingOrder as any)?.is_delivered ?? false,
    };
    if (markDelivered && !(existingOrder as any)?.delivered_at) {
        updatePayload.delivered_at = new Date().toISOString();
    }

    const { data: order, error } = await supabaseAdmin
        .from('orders')
        .update(updatePayload)
        .eq('id', id)
        .select()
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const customerPhone = (existingOrder as any)?.customer?.phone as string | undefined;
    const vendorName =
        ((existingOrder as any)?.vendor?.name as string | undefined) ||
        ((existingOrder as any)?.vendor?.business_name as string | undefined) ||
        'your vendor';
    const orderRef = (order.order_number as string | undefined) || order.id;

    if (customerPhone) {
        try {
            if (status === 'delivered' || status === 'completed') {
                await notifyOrderDelivered(customerPhone, orderRef, vendorName);
            } else if (status === 'failed') {
                await notifyDeliveryFailed(customerPhone, String((existingOrder as any)?.delivery_date || 'today'));
            }
        } catch (notificationError) {
            console.error('[PUT /api/orders/:id/status] notification failed', notificationError);
        }
    }

    return Response.json(order);
}
