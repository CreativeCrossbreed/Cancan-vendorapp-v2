import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const searchParams = req.nextUrl.searchParams;
    const period = parseInt(searchParams.get('period') || '7');

    const dateLimit = new Date();
    dateLimit.setDate(dateLimit.getDate() - period);

    const { data: orders, error } = await supabaseAdmin
        .from('orders')
        .select('total_amount, created_at, status')
        .gte('created_at', dateLimit.toISOString())
        .order('created_at', { ascending: true });

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const revenue = orders.reduce((acc: any, curr: any) => {
        if (curr.status !== 'completed') return acc;

        const date = curr.created_at.split('T')[0];
        if (!acc[date]) {
            acc[date] = { date, amount: 0 };
        }
        acc[date].amount += Number(curr.total_amount);
        return acc;
    }, {});

    return Response.json(Object.values(revenue));
}
