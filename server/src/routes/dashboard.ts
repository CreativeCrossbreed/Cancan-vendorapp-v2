import express from 'express';
import { supabase } from '../config/database';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Get dashboard statistics
router.get('/stats', authenticateToken, async (req: any, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    // Get vendor stats
    const { data: vendorStats } = await supabase
      .from('vendors')
      .select('status, is_on_vacation');

    const totalVendors = vendorStats?.length || 0;
    const activeVendors = vendorStats?.filter(v => v.status === 'active' && !v.is_on_vacation).length || 0;

    // Get customer count
    const { count: totalCustomers } = await supabase
      .from('customers')
      .select('*', { count: 'exact', head: true });

    // Get today's orders
    const { data: todayOrders } = await supabase
      .from('orders')
      .select('total_amount, status')
      .eq('delivery_date', today);

    const todayOrdersCount = todayOrders?.length || 0;
    const todayRevenue = todayOrders?.filter(o => o.status === 'completed')
      .reduce((sum, o) => sum + o.total_amount, 0) || 0;

    // Get commission stats
    const { data: commissionData } = await supabase
      .from('commission_records')
      .select('commission_amount, created_at')
      .gte('created_at', today);

    const commissionEarned = commissionData?.reduce((sum, c) => sum + c.commission_amount, 0) || 0;

    // Get WhatsApp orders
    const { count: whatsappOrdersProcessed } = await supabase
      .from('whatsapp_orders')
      .select('*', { count: 'exact', head: true })
      .gte('created_at', today);

    // Get pending payments
    const { data: pendingPayments } = await supabase
      .from('orders')
      .select('total_amount')
      .eq('payment_status', 'unpaid')
      .eq('status', 'completed');

    const totalPendingPayments = pendingPayments?.reduce((sum, o) => sum + o.total_amount, 0) || 0;

    const stats = {
      totalVendors,
      activeVendors,
      totalCustomers: totalCustomers || 0,
      todayOrders: todayOrdersCount,
      todayRevenue,
      commissionEarned,
      whatsappOrdersProcessed: whatsappOrdersProcessed || 0,
      pendingPayments: totalPendingPayments,
    };

    res.json(stats);
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get revenue analytics
router.get('/revenue', authenticateToken, async (req: any, res) => {
  try {
    const { period = '7' } = req.query; // days
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    const { data: orders } = await supabase
      .from('orders')
      .select('total_amount, created_at, status')
      .gte('created_at', startDate.toISOString())
      .order('created_at');

    // Group by date
    const revenueByDate = orders?.reduce((acc: any, order: any) => {
      const date = order.created_at.split('T')[0];
      if (!acc[date]) {
        acc[date] = { date, revenue: 0, orders: 0, completedOrders: 0 };
      }
      acc[date].orders++;
      if (order.status === 'completed') {
        acc[date].revenue += order.total_amount;
        acc[date].completedOrders++;
      }
      return acc;
    }, {});

    const revenueData = Object.values(revenueByDate || {});

    res.json(revenueData);
  } catch (error) {
    console.error('Get revenue analytics error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get top vendors by performance
router.get('/top-vendors', authenticateToken, async (req: any, res) => {
  try {
    const { period = '30' } = req.query; // days
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    const { data: vendorPerformance } = await supabase
      .from('orders')
      .select(`
        vendor_id,
        total_amount,
        status,
        vendor:vendors(name, business_name)
      `)
      .gte('created_at', startDate.toISOString());

    const vendorStats = vendorPerformance?.reduce((acc: any, order: any) => {
      const vendorId = order.vendor_id;
      if (!acc[vendorId]) {
        acc[vendorId] = {
          vendorId,
          name: order.vendor?.name || 'Unknown',
          businessName: order.vendor?.business_name || '',
          totalOrders: 0,
          completedOrders: 0,
          totalRevenue: 0,
          completionRate: 0,
        };
      }
      acc[vendorId].totalOrders++;
      if (order.status === 'completed') {
        acc[vendorId].completedOrders++;
        acc[vendorId].totalRevenue += order.total_amount;
      }
      return acc;
    }, {});

    // Calculate completion rates and sort
    const topVendors = Object.values(vendorStats || {})
      .map((vendor: any) => ({
        ...vendor,
        completionRate: vendor.totalOrders > 0 ? (vendor.completedOrders / vendor.totalOrders) * 100 : 0,
      }))
      .sort((a: any, b: any) => b.totalRevenue - a.totalRevenue)
      .slice(0, 10);

    res.json(topVendors);
  } catch (error) {
    console.error('Get top vendors error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get recent activities
router.get('/recent-activities', authenticateToken, async (req: any, res) => {
  try {
    const limit = 20;

    // Get recent orders
    const { data: recentOrders } = await supabase
      .from('orders')
      .select(`
        created_at,
        order_number,
        status,
        customer:customers(name),
        vendor:vendors(name)
      `)
      .order('created_at', { ascending: false })
      .limit(limit);

    // Get new customers
    const { data: newCustomers } = await supabase
      .from('customers')
      .select('created_at, name, phone')
      .order('created_at', { ascending: false })
      .limit(5);

    // Get new vendors
    const { data: newVendors } = await supabase
      .from('vendors')
      .select('created_at, name, business_name')
      .order('created_at', { ascending: false })
      .limit(5);

    const activities = [
      ...recentOrders?.map(order => ({
        type: 'order',
        id: order.order_number,
        description: `Order ${order.order_number} - ${order.status}`,
        details: `${order.customer?.name} → ${order.vendor?.name}`,
        timestamp: order.created_at,
      })) || [],
      ...newCustomers?.map(customer => ({
        type: 'customer',
        id: customer.phone,
        description: 'New customer registered',
        details: customer.name,
        timestamp: customer.created_at,
      })) || [],
      ...newVendors?.map(vendor => ({
        type: 'vendor',
        id: vendor.name,
        description: 'New vendor registered',
        details: vendor.business_name || vendor.name,
        timestamp: vendor.created_at,
      })) || [],
    ]
      .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
      .slice(0, limit);

    res.json(activities);
  } catch (error) {
    console.error('Get recent activities error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get order status distribution
router.get('/order-distribution', authenticateToken, async (req: any, res) => {
  try {
    const { period = '7' } = req.query; // days
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    const { data: orders } = await supabase
      .from('orders')
      .select('status, payment_status')
      .gte('created_at', startDate.toISOString());

    const distribution = {
      pending: orders?.filter(o => o.status === 'pending').length || 0,
      completed: orders?.filter(o => o.status === 'completed').length || 0,
      cancelled: orders?.filter(o => o.status === 'cancelled').length || 0,
      paid: orders?.filter(o => o.payment_status === 'paid').length || 0,
      unpaid: orders?.filter(o => o.payment_status === 'unpaid').length || 0,
    };

    res.json(distribution);
  } catch (error) {
    console.error('Get order distribution error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;