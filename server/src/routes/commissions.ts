import express from 'express';
import { supabase } from '../config/database';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Get all commission records with pagination
router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status as string;
    const vendor_id = req.query.vendor_id as string;
    const date_from = req.query.date_from as string;
    const date_to = req.query.date_to as string;

    let query = supabase
      .from('commission_records')
      .select(`
        *,
        vendor:vendors(name, business_name),
        order:orders(order_number, total_amount, created_at)
      `, { count: 'exact' })
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (status) query = query.eq('status', status);
    if (vendor_id) query = query.eq('vendor_id', vendor_id);
    if (date_from) query = query.gte('created_at', date_from);
    if (date_to) query = query.lte('created_at', date_to);

    const { data: commissions, error, count } = await query;

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json({
      commissions,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (error) {
    console.error('Get commissions error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get commission statistics
router.get('/stats', authenticateToken, async (req: any, res) => {
  try {
    const { period = '30' } = req.query; // days
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    // Get commission records
    const { data: commissions } = await supabase
      .from('commission_records')
      .select('*')
      .gte('created_at', startDate.toISOString());

    const stats = {
      totalCommission: commissions?.reduce((sum, c) => sum + c.commission_amount, 0) || 0,
      paidCommission: commissions?.filter(c => c.status === 'paid')
        .reduce((sum, c) => sum + c.commission_amount, 0) || 0,
      pendingCommission: commissions?.filter(c => c.status === 'pending')
        .reduce((sum, c) => sum + c.commission_amount, 0) || 0,
      totalOrders: commissions?.length || 0,
      paidOrders: commissions?.filter(c => c.status === 'paid').length || 0,
      pendingOrders: commissions?.filter(c => c.status === 'pending').length || 0,
      averageCommission: 0,
    };

    if (stats.totalOrders > 0) {
      stats.averageCommission = stats.totalCommission / stats.totalOrders;
    }

    res.json(stats);
  } catch (error) {
    console.error('Get commission stats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get vendor-wise commission breakdown
router.get('/vendor-breakdown', authenticateToken, async (req: any, res) => {
  try {
    const { period = '30' } = req.query; // days
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    const { data: commissions } = await supabase
      .from('commission_records')
      .select(`
        *,
        vendor:vendors(name, business_name)
      `)
      .gte('created_at', startDate.toISOString());

    const vendorBreakdown = commissions?.reduce((acc: any, commission: any) => {
      const vendorId = commission.vendor_id;
      if (!acc[vendorId]) {
        acc[vendorId] = {
          vendorId,
          vendorName: commission.vendor?.name || 'Unknown',
          businessName: commission.vendor?.business_name || '',
          totalCommission: 0,
          paidCommission: 0,
          pendingCommission: 0,
          totalOrders: 0,
          paidOrders: 0,
          pendingOrders: 0,
          averageOrderValue: 0,
        };
      }

      acc[vendorId].totalCommission += commission.commission_amount;
      acc[vendorId].totalOrders++;
      acc[vendorId].averageOrderValue += commission.order_amount;

      if (commission.status === 'paid') {
        acc[vendorId].paidCommission += commission.commission_amount;
        acc[vendorId].paidOrders++;
      } else {
        acc[vendorId].pendingCommission += commission.commission_amount;
        acc[vendorId].pendingOrders++;
      }

      return acc;
    }, {});

    // Calculate average order value
    Object.values(vendorBreakdown || {}).forEach((vendor: any) => {
      if (vendor.totalOrders > 0) {
        vendor.averageOrderValue = vendor.averageOrderValue / vendor.totalOrders;
      }
    });

    const breakdown = Object.values(vendorBreakdown || {})
      .sort((a: any, b: any) => b.totalCommission - a.totalCommission);

    res.json(breakdown);
  } catch (error) {
    console.error('Get vendor breakdown error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create commission record for order
router.post('/', authenticateToken, async (req: any, res) => {
  try {
    const { order_id, vendor_id, commission_rate } = req.body;

    if (!order_id || !vendor_id || commission_rate === undefined) {
      return res.status(400).json({ error: 'Order ID, Vendor ID, and commission rate are required' });
    }

    // Get order details
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('total_amount')
      .eq('id', order_id)
      .single();

    if (orderError || !order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    // Calculate commission
    const commission_amount = (order.total_amount * commission_rate) / 100;

    // Check if commission already exists for this order
    const { data: existingCommission } = await supabase
      .from('commission_records')
      .select('id')
      .eq('order_id', order_id)
      .single();

    if (existingCommission) {
      return res.status(400).json({ error: 'Commission record already exists for this order' });
    }

    // Create commission record
    const { data: commission, error } = await supabase
      .from('commission_records')
      .insert([{
        order_id,
        vendor_id,
        commission_amount,
        order_amount: order.total_amount,
        commission_rate,
        status: 'pending',
      }])
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.status(201).json(commission);
  } catch (error) {
    console.error('Create commission error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update commission status (mark as paid)
router.put('/:id/status', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['pending', 'paid'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const updateData: any = { status };
    if (status === 'paid') {
      updateData.paid_at = new Date().toISOString();
    }

    const { data: commission, error } = await supabase
      .from('commission_records')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    if (!commission) {
      return res.status(404).json({ error: 'Commission record not found' });
    }

    res.json(commission);
  } catch (error) {
    console.error('Update commission status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Bulk update commission status
router.put('/bulk-status', authenticateToken, async (req: any, res) => {
  try {
    const { commission_ids, status } = req.body;

    if (!commission_ids || !Array.isArray(commission_ids) || !['pending', 'paid'].includes(status)) {
      return res.status(400).json({ error: 'Invalid request' });
    }

    const updateData: any = { status };
    if (status === 'paid') {
      updateData.paid_at = new Date().toISOString();
    }

    const { data: commissions, error } = await supabase
      .from('commission_records')
      .update(updateData)
      .in('id', commission_ids)
      .select();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: `Updated ${commissions?.length || 0} commission records`,
      commissions,
    });
  } catch (error) {
    console.error('Bulk update commission error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get commission trends
router.get('/trends', authenticateToken, async (req: any, res) => {
  try {
    const { period = '30' } = req.query; // days
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    const { data: commissions } = await supabase
      .from('commission_records')
      .select('created_at, commission_amount, status')
      .gte('created_at', startDate.toISOString());

    // Group by date
    const trends = commissions?.reduce((acc: any, commission: any) => {
      const date = commission.created_at.split('T')[0];
      if (!acc[date]) {
        acc[date] = {
          date,
          totalCommission: 0,
          paidCommission: 0,
          pendingCommission: 0,
          count: 0,
        };
      }
      acc[date].totalCommission += commission.commission_amount;
      acc[date].count++;
      if (commission.status === 'paid') {
        acc[date].paidCommission += commission.commission_amount;
      } else {
        acc[date].pendingCommission += commission.commission_amount;
      }
      return acc;
    }, {});

    res.json(Object.values(trends || {}));
  } catch (error) {
    console.error('Get commission trends error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;