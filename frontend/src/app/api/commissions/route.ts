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
        .from('commission_ledger')
        .select(`
            *,
            vendors!inner ( id, name, phone ),
            orders!inner ( id, total_amount, delivery_date )
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

    const normalized = (commissions || []).map((row: Record<string, unknown>) => ({
        id: row.id,
        order_id: row.order_id,
        vendor_id: row.vendor_id,
        commission_amount: Number(row.commission_amount || 0),
        order_total: Number(row.gross_amount || (row.orders as Record<string, unknown> | undefined)?.total_amount || 0),
        commission_rate:
            row.commission_type === 'percentage'
                ? Number(row.commission_percentage || 0)
                : Number(row.per_bottle_commission || 0),
        status:
            row.status === 'settled'
                ? 'paid'
                : row.status === 'accrued'
                  ? 'processing'
                  : row.status === 'reversed'
                    ? 'cancelled'
                    : 'pending',
        created_at: row.created_at,
        paid_at: row.status === 'settled' ? row.updated_at : null,
        order_date: (row.orders as Record<string, unknown> | undefined)?.delivery_date || null,
        vendor: row.vendors || null,
    }));

    return Response.json({
        commissions: normalized,
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
    const payload = {
        order_id: data.order_id,
        vendor_id: data.vendor_id,
        customer_id: data.customer_id || null,
        commission_type: data.commission_type || 'per_bottle',
        qty: data.qty || 0,
        per_bottle_commission: data.per_bottle_commission || 0,
        commission_percentage: data.commission_percentage || 0,
        gross_amount: data.order_total || data.gross_amount || 0,
        commission_amount: data.commission_amount || 0,
        net_vendor_amount:
            data.net_vendor_amount ||
            Math.max(Number(data.order_total || data.gross_amount || 0) - Number(data.commission_amount || 0), 0),
        status: data.status || 'pending',
        rule_snapshot: data.rule_snapshot || { source: 'admin_manual' },
    };

    const { data: commission, error } = await supabaseAdmin
        .from('commission_ledger')
        .insert([payload])
        .select('*')
        .single();

    if (error) {
        return Response.json({ error: error.message }, { status: 500 });
    }

    return Response.json(commission);
}
