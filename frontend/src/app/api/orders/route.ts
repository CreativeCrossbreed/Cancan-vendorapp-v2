import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

/** Map DB vendor row (name vs owner_name) to what the portal UI expects */
function normalizeOrderRow(row: Record<string, unknown>) {
    const customer = row.customer as Record<string, unknown> | null | undefined;
    const vendor = row.vendor as Record<string, unknown> | null | undefined;
    const { customer: _c, vendor: _v, ...rest } = row;
    return {
        ...rest,
        customer: customer
            ? {
                  ...customer,
                  name: (customer.name ?? customer.owner_name ?? '') as string,
              }
            : null,
        vendor: vendor
            ? {
                  name: (vendor.name ?? vendor.owner_name ?? '') as string,
                  business_name: vendor.business_name as string | undefined,
                  phone: vendor.phone as string | undefined,
              }
            : null,
    };
}

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

    // Use * on nested tables so both schemas work (e.g. unified_schema uses owner_name, simple schema uses name)
    let query = supabaseAdmin
        .from('orders')
        .select(
            `
      *,
      customer:customers(*),
      vendor:vendors(*)
    `,
            { count: 'exact' },
        );

    if (status && status !== 'all') query = query.eq('status', status);
    if (payment_status && payment_status !== 'all') query = query.eq('payment_status', payment_status);
    if (date_from) query = query.gte('delivery_date', date_from);
    if (date_to) query = query.lte('delivery_date', date_to);

    const { data: orders, count, error } = await query
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

    if (error) {
        console.error('[GET /api/orders] Supabase error:', error.message, error);
        return Response.json({ error: error.message }, { status: 500 });
    }

    const normalizedOrders = (orders ?? []).map((row) => normalizeOrderRow(row as Record<string, unknown>));

    return Response.json({
        orders: normalizedOrders,
        pagination: {
            page,
            limit,
            total: count || 0,
            totalPages: Math.ceil((count || 0) / limit),
        },
    });
}

