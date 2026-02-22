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
        .select('status')
        .gte('created_at', dateLimit.toISOString());

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const distribution = orders.reduce((acc: any, curr: any) => {
        acc[curr.status] = (acc[curr.status] || 0) + 1;
        return acc;
    }, {});

    const formattedDistribution = Object.keys(distribution).map((status) => ({
        name: status.charAt(0).toUpperCase() + status.slice(1),
        value: distribution[status],
    }));

    return Response.json(formattedDistribution);
}
