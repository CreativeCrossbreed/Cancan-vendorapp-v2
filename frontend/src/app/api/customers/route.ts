import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    const searchParams = req.nextUrl.searchParams;
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');
    const search = searchParams.get('search');
    const has_orders = searchParams.get('has_orders');

    let query = supabaseAdmin
        .from('customers')
        .select('*', { count: 'exact' });

    if (search) {
        query = query.or(`name.ilike.%${search}%,phone.ilike.%${search}%`);
    }
    if (has_orders === 'true') {
        query = query.gt('total_orders', 0);
    }

    const { data: customers, count, error } = await query
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json({
        customers,
        pagination: {
            page,
            limit,
            total: count || 0,
            totalPages: Math.ceil((count || 0) / limit),
        },
    });
}

