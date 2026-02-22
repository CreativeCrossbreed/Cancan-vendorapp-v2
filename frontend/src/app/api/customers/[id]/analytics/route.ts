import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { id } = await params;

    const { data: orders, error } = await supabaseAdmin
        .from('orders')
        .select('total_amount, status, created_at')
        .eq('customer_id', id);

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    let totalSpent = 0;

    orders.forEach((o: any) => {
        if (o.status === 'completed') {
            totalSpent += Number(o.total_amount);
        }
    });

    return Response.json({
        totalOrders: orders.length,
        totalSpent,
        lastOrderDate: orders.length ? orders[orders.length - 1].created_at : null
    });
}
