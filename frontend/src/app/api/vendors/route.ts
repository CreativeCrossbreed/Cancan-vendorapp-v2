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
    const search = searchParams.get('search');

    let query = supabaseAdmin
        .from('vendors')
        .select('*', { count: 'exact' });

    if (status && status !== 'all') {
        query = query.eq('status', status);
    }
    if (search) {
        query = query.or(`name.ilike.%${search}%,business_name.ilike.%${search}%,phone.ilike.%${search}%`);
    }

    const { data: vendors, count, error } = await query
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

    if (error) {
        console.error('[GET /api/vendors] Supabase error:', error.message, error);
        return Response.json({ error: error.message }, { status: 500 });
    }

    // Get stats for these vendors
    const vendorIds = vendors?.map((v) => v.id) || [];
    const { data: stats } = await supabaseAdmin
        .from('orders')
        .select('vendor_id, status, total_amount')
        .in('vendor_id', vendorIds);

    const vendorStats = stats?.reduce((acc: any, stat: any) => {
        if (!acc[stat.vendor_id]) {
            acc[stat.vendor_id] = { totalOrders: 0, completedOrders: 0, totalRevenue: 0 };
        }
        acc[stat.vendor_id].totalOrders++;
        if (stat.status === 'completed' || stat.status === 'delivered') {
            acc[stat.vendor_id].completedOrders++;
            acc[stat.vendor_id].totalRevenue += Number(stat.total_amount) || 0;
        }
        return acc;
    }, {});

    const vendorsWithStats = vendors?.map((vendor) => ({
        ...vendor,
        stats: vendorStats?.[vendor.id] || { totalOrders: 0, completedOrders: 0, totalRevenue: 0 },
    }));

    return Response.json({
        vendors: vendorsWithStats,
        pagination: {
            page,
            limit,
            total: count || 0,
            totalPages: Math.ceil((count || 0) / limit),
        },
    });
}

