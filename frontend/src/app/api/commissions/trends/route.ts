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

    const { data: commissions, error } = await supabaseAdmin
        .from('commission_ledger')
        .select('commission_amount, status, created_at')
        .gte('created_at', dateLimit.toISOString())
        .order('created_at', { ascending: true });

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    // Group by date (YYYY-MM-DD)
    const trends = (commissions || []).reduce((acc: Record<string, { date: string; amount: number; paid: number; pending: number }>, curr: Record<string, unknown>) => {
        const date = String(curr.created_at || '').split('T')[0];
        if (!acc[date]) {
            acc[date] = { date, amount: 0, paid: 0, pending: 0 };
        }
        const amount = Number(curr.commission_amount || 0);
        acc[date].amount += amount;
        if (curr.status === 'settled') acc[date].paid += amount;
        else acc[date].pending += amount;
        return acc;
    }, {});

    return Response.json(Object.values(trends));
}
