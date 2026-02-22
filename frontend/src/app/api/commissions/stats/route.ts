import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const { data: stats, error } = await supabaseAdmin
        .from('commissions')
        .select('amount, status');

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const aggregated = stats.reduce(
        (acc, curr) => {
            acc.total += Number(curr.amount);
            if (curr.status === 'paid') acc.paid += Number(curr.amount);
            if (curr.status === 'pending') acc.pending += Number(curr.amount);
            return acc;
        },
        { total: 0, paid: 0, pending: 0 }
    );

    return Response.json(aggregated);
}
