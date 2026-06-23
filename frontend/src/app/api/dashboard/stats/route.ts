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
            .select('status, total_amount, vendor_id, payment_status')
            .gte('created_at', today);

        const todayOrdersCount = todayOrders?.length || 0;
        const todayRevenue = todayOrders
            ?.filter(o => o.status === 'completed' || o.status === 'delivered')
            .reduce((sum, o) => sum + (Number(o.total_amount) || 0), 0) || 0;

        const unassignedOrders = todayOrders?.filter(o => !o.vendor_id).length || 0;
        const unpaidDeliveredOrders =
            todayOrders?.filter(
                o => (o.status === 'completed' || o.status === 'delivered') && o.payment_status !== 'paid',
            ).length || 0;

        // Commission earned today
        const { data: todayCommissions } = await supabaseAdmin
            .from('commission_ledger')
            .select('commission_amount')
            .gte('created_at', today);

        const commissionEarned = (todayCommissions || []).reduce(
            (sum: number, row: Record<string, unknown>) => sum + Number(row.commission_amount || 0),
            0,
        );

        // Pending vendor payouts (available wallet balances)
        const { data: walletRows } = await supabaseAdmin
            .from('vendor_wallet_ledger')
            .select('vendor_id, entry_type, amount, status')
            .eq('status', 'posted');

        const walletByVendor = new Map<string, number>();
        for (const row of walletRows || []) {
            const sign = row.entry_type === 'debit' || row.entry_type === 'reversal' ? -1 : 1;
            const next = Number((walletByVendor.get(row.vendor_id) || 0) + sign * Number(row.amount || 0));
            walletByVendor.set(row.vendor_id, next);
        }
        const pendingPayouts = [...walletByVendor.values()]
            .filter((v) => v > 0)
            .reduce((sum, value) => sum + value, 0);

        // WhatsApp message volume for today as processed count
        const { count: whatsappProcessed } = await supabaseAdmin
            .from('whatsapp_messages')
            .select('*', { count: 'exact', head: true })
            .eq('direction', 'inbound')
            .gte('created_at', today);

        const { count: failedOutboundWhatsApp } = await supabaseAdmin
            .from('whatsapp_messages')
            .select('*', { count: 'exact', head: true })
            .eq('direction', 'outbound')
            .eq('status', 'failed')
            .gte('created_at', today);

        const stats = {
            totalVendors,
            activeVendors,
            totalCustomers: totalCustomers || 0,
            todayOrders: todayOrdersCount,
            todayRevenue,
            commissionEarned: Number(commissionEarned.toFixed(2)),
            whatsappOrdersProcessed: whatsappProcessed || 0,
            pendingPayments: Number(pendingPayouts.toFixed(2)),
            unassignedOrders,
            unpaidDeliveredOrders,
            failedOutboundWhatsApp: failedOutboundWhatsApp || 0,
        };

        return Response.json(stats);
    } catch (error) {
        console.error('Dashboard stats error:', error);
        return Response.json({ error: 'Internal server error' }, { status: 500 });
    }
}

