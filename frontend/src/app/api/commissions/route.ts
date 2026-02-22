import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const searchParams = req.nextUrl.searchParams;
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');
    const status = searchParams.get('status');
    const vendor_id = searchParams.get('vendor_id');

    let query = supabaseAdmin
        .from('commissions')
        .select(`
            *,
            vendors!inner ( name ),
            orders!inner ( total_amount, id )
        `, { count: 'exact' });

    if (status && status !== 'all') {
        query = query.eq('status', status);
    }
    if (vendor_id && vendor_id !== 'all') {
        query = query.eq('vendor_id', vendor_id);
    }

    const { data: commissions, count, error } = await query
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json({
        commissions,
        pagination: {
            page,
            limit,
            total: count || 0,
            totalPages: Math.ceil((count || 0) / limit),
        },
    });
}

export async function POST(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    if (admin.role !== 'super_admin') {
        return Response.json({ error: 'Only super admins can generate commissions' }, { status: 403 });
    }

    const data = await req.json();

    const { data: commission, error } = await supabaseAdmin
        .from('commissions')
        .insert([data])
        .select()
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json(commission);
}
