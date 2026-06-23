import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;
    const searchParams = req.nextUrl.searchParams;
    const period = parseInt(searchParams.get('period') || '30');

    const dateLimit = new Date();
    dateLimit.setDate(dateLimit.getDate() - period);

    const { data: orders, error } = await supabaseAdmin
        .from('orders')
        .select('total_amount, status, created_at')
        .eq('vendor_id', id)
        .gte('created_at', dateLimit.toISOString());

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    let revenue = 0;
    let completedOrders = 0;

    orders.forEach((o: any) => {
        if (o.status === 'completed' || o.status === 'delivered') {
            revenue += Number(o.total_amount);
            completedOrders++;
        }
    });

    return Response.json({
        totalOrders: orders.length,
        completedOrders,
        revenue,
        completionRate: orders.length ? (completedOrders / orders.length) * 100 : 0
    });
}
