import { NextRequest } from 'next/server';
import { supabaseAdmin } from '@/lib/supabase';
import { authenticateAdmin, unauthorized } from '@/lib/auth';

export async function GET(req: NextRequest) {
    const admin = await authenticateAdmin(req);
    if (!admin) return unauthorized();

    try {
        const today = new Date().toISOString().split('T')[0];

        // Get vendor stats
        const { data: vendorStats } = await supabaseAdmin
            .from('vendors')
            .select('status, is_on_vacation');

        const totalVendors = vendorStats?.length || 0;
        const activeVendors = vendorStats?.filter(v => v.status === 'active' && !v.is_on_vacation).length || 0;

        // Get customer stats
        const { count: totalCustomers } = await supabaseAdmin
            .from('customers')
            .select('*', { count: 'exact', head: true });

        // Get today's orders
        const { data: todayOrders } = await supabaseAdmin
            .from('orders')
            .select('status, total_amount')
            .gte('created_at', today);

        const todayOrdersCount = todayOrders?.length || 0;
        const todayRevenue = todayOrders
            ?.filter(o => o.status === 'completed')
            .reduce((sum, o) => sum + (Number(o.total_amount) || 0), 0) || 0;

        const stats = {
            totalVendors,
            activeVendors,
            totalCustomers: totalCustomers || 0,
            todayOrders: todayOrdersCount,
            todayRevenue,
            commissionEarned: todayRevenue * 0.1, // Mock 10%
            whatsappOrdersProcessed: 15, // Mock value
            pendingPayments: 0,
        };

        return Response.json(stats);
    } catch (error) {
        console.error('Dashboard stats error:', error);
        return Response.json({ error: 'Internal server error' }, { status: 500 });
    }
}

