import express from 'express';
import { supabase } from '../config/database';
import { authenticateToken, requireRole } from '../middleware/auth';

const router = express.Router();

// Get all vendors with pagination and filtering
router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status as string;
    const search = req.query.search as string;

    let query = supabase
      .from('vendors')
      .select('*, vendor_products(product:products(id, name))', { count: 'exact' })
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    if (search) {
      query = query.or(`name.ilike.%${search}%,business_name.ilike.%${search}%,phone.ilike.%${search}%`);
    }

    const { data: vendors, error, count } = await query;

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    // Get additional stats for each vendor
    const vendorIds = vendors?.map(v => v.id) || [];
    const { data: stats } = await supabase
      .from('orders')
      .select('vendor_id, status, total_amount, commission_records!inner(commission_amount)')
      .in('vendor_id', vendorIds);

    const vendorStats = stats?.reduce((acc: any, stat: any) => {
      if (!acc[stat.vendor_id]) {
        acc[stat.vendor_id] = {
          totalOrders: 0,
          completedOrders: 0,
          totalRevenue: 0,
          totalCommission: 0,
        };
      }
      acc[stat.vendor_id].totalOrders++;
      if (stat.status === 'completed') {
        acc[stat.vendor_id].completedOrders++;
      }
      acc[stat.vendor_id].totalRevenue += stat.total_amount;
      acc[stat.vendor_id].totalCommission += stat.commission_records?.commission_amount || 0;
      return acc;
    }, {});

    const vendorsWithStats = vendors?.map(vendor => ({
      ...vendor,
      stats: vendorStats?.[vendor.id] || {
        totalOrders: 0,
        completedOrders: 0,
        totalRevenue: 0,
        totalCommission: 0,
      },
    }));

    res.json({
      vendors: vendorsWithStats,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (error) {
    console.error('Get vendors error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get vendor by ID
router.get('/:id', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;

    const { data: vendor, error } = await supabase
      .from('vendors')
      .select(`
        *,
        vendor_products(
          *,
          product:products(*)
        )
      `)
      .eq('id', id)
      .single();

    if (error) {
      return res.status(404).json({ error: 'Vendor not found' });
    }

    // Get vendor's orders
    const { data: orders } = await supabase
      .from('orders')
      .select('*, customer:customers(*)')
      .eq('vendor_id', id)
      .order('created_at', { ascending: false })
      .limit(10);

    res.json({
      vendor,
      recentOrders: orders || [],
    });
  } catch (error) {
    console.error('Get vendor error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create new vendor
router.post('/', authenticateToken, requireRole(['super_admin', 'operations']), async (req: any, res) => {
  try {
    const {
      phone,
      name,
      business_name,
      address,
      commission_rate,
      status = 'active',
    } = req.body;

    if (!phone || !name) {
      return res.status(400).json({ error: 'Phone and name are required' });
    }

    const { data: vendor, error } = await supabase
      .from('vendors')
      .insert([{
        phone,
        name,
        business_name,
        address,
        commission_rate: commission_rate || 10.0,
        status,
        is_on_vacation: status !== 'active',
      }])
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.status(201).json(vendor);
  } catch (error) {
    console.error('Create vendor error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update vendor
router.put('/:id', authenticateToken, requireRole(['super_admin', 'operations']), async (req: any, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      business_name,
      address,
      commission_rate,
      status,
      is_on_vacation,
    } = req.body;

    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (business_name !== undefined) updateData.business_name = business_name;
    if (address !== undefined) updateData.address = address;
    if (commission_rate !== undefined) updateData.commission_rate = commission_rate;
    if (status !== undefined) updateData.status = status;
    if (is_on_vacation !== undefined) updateData.is_on_vacation = is_on_vacation;

    const { data: vendor, error } = await supabase
      .from('vendors')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    if (!vendor) {
      return res.status(404).json({ error: 'Vendor not found' });
    }

    res.json(vendor);
  } catch (error) {
    console.error('Update vendor error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete vendor
router.delete('/:id', authenticateToken, requireRole(['super_admin']), async (req: any, res) => {
  try {
    const { id } = req.params;

    // Check if vendor has orders
    const { data: orders } = await supabase
      .from('orders')
      .select('id')
      .eq('vendor_id', id)
      .limit(1);

    if (orders && orders.length > 0) {
      return res.status(400).json({ error: 'Cannot delete vendor with existing orders' });
    }

    const { error } = await supabase
      .from('vendors')
      .delete()
      .eq('id', id);

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({ message: 'Vendor deleted successfully' });
  } catch (error) {
    console.error('Delete vendor error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get vendor performance stats
router.get('/:id/stats', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;
    const { period = '30' } = req.query; // days

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    const { data: orders } = await supabase
      .from('orders')
      .select('status, total_amount, created_at')
      .eq('vendor_id', id)
      .gte('created_at', startDate.toISOString());

    const { data: commissions } = await supabase
      .from('commission_records')
      .select('commission_amount, status')
      .eq('vendor_id', id)
      .gte('created_at', startDate.toISOString());

    const stats = {
      totalOrders: orders?.length || 0,
      completedOrders: orders?.filter(o => o.status === 'completed').length || 0,
      cancelledOrders: orders?.filter(o => o.status === 'cancelled').length || 0,
      totalRevenue: orders?.reduce((sum, o) => sum + o.total_amount, 0) || 0,
      totalCommission: commissions?.reduce((sum, c) => sum + c.commission_amount, 0) || 0,
      paidCommission: commissions?.filter(c => c.status === 'paid').reduce((sum, c) => sum + c.commission_amount, 0) || 0,
      pendingCommission: commissions?.filter(c => c.status === 'pending').reduce((sum, c) => sum + c.commission_amount, 0) || 0,
    };

    res.json(stats);
  } catch (error) {
    console.error('Get vendor stats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;