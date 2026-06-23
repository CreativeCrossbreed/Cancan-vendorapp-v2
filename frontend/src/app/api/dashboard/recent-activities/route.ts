import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const limit = 10;
    const activities: Array<Record<string, unknown>> = [];

    // Get latest orders
    const { data: orders } = await supabaseAdmin
        .from('orders')
        .select(`
            id, total_amount, status, created_at,
            customers!inner ( name ), vendors ( name )
        `)
        .order('created_at', { ascending: false })
        .limit(limit);

    if (orders) {
        orders.forEach((o: Record<string, unknown>) => {
            activities.push({
                id: `order_${o.id}`,
                type: 'order',
                action: o.status === 'pending' ? 'New order placed' : `Order ${o.status}`,
                details: `${(o.customers as Record<string, unknown>)?.name || 'Customer'} - ₹${o.total_amount}`,
                metadata: { order_id: o.id, vendor: (o.vendors as Record<string, unknown> | undefined)?.name },
                timestamp: o.created_at,
            });
        });
    }

    // Latest payout activities
    const { data: payouts } = await supabaseAdmin
        .from('payout_items')
        .select(`
            id, amount, status, created_at, paid_at, vendor_id,
            vendors ( name )
        `)
        .order('created_at', { ascending: false })
        .limit(limit);

    if (payouts) {
        payouts.forEach((p: Record<string, unknown>) => {
            activities.push({
                id: `payout_${p.id}`,
                type: 'payout',
                action: p.status === 'paid' ? 'Vendor payout completed' : `Vendor payout ${p.status}`,
                details: `${(p.vendors as Record<string, unknown> | undefined)?.name || 'Vendor'} - ₹${Number(p.amount || 0).toFixed(0)}`,
                metadata: { payout_item_id: p.id, vendor_id: p.vendor_id },
                timestamp: p.paid_at || p.created_at,
            });
        });
    }

    // Get latest vendor signups
    const { data: vendors } = await supabaseAdmin
        .from('vendors')
        .select('id, name, business_name, created_at')
        .order('created_at', { ascending: false })
        .limit(limit);

    if (vendors) {
        vendors.forEach((v: Record<string, unknown>) => {
            activities.push({
                id: `vendor_${v.id}`,
                type: 'vendor',
                action: 'New vendor registered',
                details: `${v.business_name} (${v.name})`,
                metadata: { vendor_id: v.id },
                timestamp: v.created_at,
            });
        });
    }

    // Sort combined activities by timestamp and return top `limit`
    activities.sort(
        (a, b) =>
            new Date(String(b.timestamp || '')).getTime() - new Date(String(a.timestamp || '')).getTime(),
    );

    return Response.json(activities.slice(0, limit));
}
