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
    const payment_status = searchParams.get('payment_status');
    const date_from = searchParams.get('date_from');
    const date_to = searchParams.get('date_to');

    let query = supabaseAdmin
        .from('orders')
        .select(`
      *,
      customer:customers(name, phone, address),
      vendor:vendors(name, business_name, phone)
    `, { count: 'exact' });

    if (status && status !== 'all') query = query.eq('status', status);
    if (payment_status && payment_status !== 'all') query = query.eq('payment_status', payment_status);
    if (date_from) query = query.gte('delivery_date', date_from);
    if (date_to) query = query.lte('delivery_date', date_to);

    const { data: orders, count, error } = await query
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json({
        orders,
        pagination: {
            page,
            limit,
            total: count || 0,
            totalPages: Math.ceil((count || 0) / limit),
        },
    });
}

