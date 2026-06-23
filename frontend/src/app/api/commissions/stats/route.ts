import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const searchParams = req.nextUrl.searchParams;
    const period = parseInt(searchParams.get('period') || '30', 10);
    const dateLimit = new Date();
    dateLimit.setDate(dateLimit.getDate() - period);

    const { data: stats, error } = await supabaseAdmin
        .from('commission_ledger')
        .select('commission_amount, status, created_at')
        .gte('created_at', dateLimit.toISOString());

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const aggregated = (stats || []).reduce(
        (acc, curr) => {
            const amount = Number(curr.commission_amount || 0);
            acc.totalEarnings += amount;
            if (curr.status === 'settled') acc.totalPaid += amount;
            else if (curr.status === 'reversed') acc.totalUnpaid += amount;
            else acc.totalPending += amount;
            return acc;
        },
        { totalEarnings: 0, totalPaid: 0, totalPending: 0, totalUnpaid: 0 }
    );

    return Response.json(aggregated);
}
