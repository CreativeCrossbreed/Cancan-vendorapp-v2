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
        .select(`
            commission_amount, vendor_id, status,
            vendors!inner ( id, name )
        `)
        .gte('created_at', dateLimit.toISOString());

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const breakdown = (commissions || []).reduce((acc: Record<string, { vendor_id: string; name: string; total: number; pending: number; paid: number }>, curr: Record<string, unknown>) => {
        const vendorId = String(curr.vendor_id || '');
        const vendorName = ((curr.vendors as Record<string, unknown> | undefined)?.name as string | undefined) || 'Unknown';

        if (!acc[vendorId]) {
            acc[vendorId] = {
                vendor_id: vendorId,
                name: vendorName,
                total: 0,
                pending: 0,
                paid: 0,
            };
        }
        const amount = Number(curr.commission_amount || 0);
        acc[vendorId].total += amount;
        if (curr.status === 'settled') acc[vendorId].paid += amount;
        else acc[vendorId].pending += amount;
        return acc;
    }, {});

    // Sort top vendors
    const sorted = Object.values(breakdown).sort((a, b) => b.total - a.total);

    return Response.json(sorted);
}
