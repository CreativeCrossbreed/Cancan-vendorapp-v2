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
        .from('commissions')
        .select(`
            amount, vendor_id,
            vendors!inner ( name )
        `)
        .gte('created_at', dateLimit.toISOString());

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    const breakdown = commissions.reduce((acc: any, curr: any) => {
        const vendorId = curr.vendor_id;
        const vendorName = curr.vendors?.name || 'Unknown';

        if (!acc[vendorId]) {
            acc[vendorId] = { vendor_id: vendorId, name: vendorName, total: 0 };
        }
        acc[vendorId].total += Number(curr.amount);
        return acc;
    }, {});

    // Sort top vendors
    const sorted = Object.values(breakdown).sort((a: any, b: any) => b.total - a.total);

    return Response.json(sorted);
}
