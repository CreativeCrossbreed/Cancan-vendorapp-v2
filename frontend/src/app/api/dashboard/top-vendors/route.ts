import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const searchParams = req.nextUrl.searchParams;
    const period = parseInt(searchParams.get('period') || '30');

    const dateLimit = new Date();
    dateLimit.setDate(dateLimit.getDate() - period);

    const { data: orders, error } = await supabaseAdmin
        .from('orders')
        .select(`
            total_amount, vendor_id, status,
            vendors!inner ( name )
        `)
        .gte('created_at', dateLimit.toISOString())
        .eq('status', 'completed');

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const breakdown = orders.reduce((acc: any, curr: any) => {
        const vendorId = curr.vendor_id;
        const vendorName = curr.vendors?.name || 'Unknown';

        if (!acc[vendorId]) {
            acc[vendorId] = { vendor_id: vendorId, name: vendorName, total: 0, orderCount: 0 };
        }
        acc[vendorId].total += Number(curr.total_amount);
        acc[vendorId].orderCount += 1;
        return acc;
    }, {});

    // Sort top vendors by total revenue
    const sorted = Object.values(breakdown).sort((a: any, b: any) => b.total - a.total).slice(0, 5); // top 5

    return Response.json(sorted);
}
