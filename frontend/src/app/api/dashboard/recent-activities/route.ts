import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const limit = 10;
    const activities: any[] = [];

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
        orders.forEach((o: any) => {
            activities.push({
                id: `order_${o.id}`,
                type: 'order',
                action: o.status === 'pending' ? 'New order placed' : `Order ${o.status}`,
                details: `${o.customers.name} - $${o.total_amount}`,
                metadata: { order_id: o.id, vendor: o.vendors?.name },
                timestamp: o.created_at,
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
        vendors.forEach((v: any) => {
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
    activities.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

    return Response.json(activities.slice(0, limit));
}
