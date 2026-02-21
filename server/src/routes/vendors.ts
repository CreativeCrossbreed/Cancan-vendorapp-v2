import express from 'express';
import { supabase, supabaseAdmin, db } from '../config/database';
import { authenticateToken, authenticateVendorToken, requireRole, requireAdmin, requireVendor } from '../middleware/auth';

const router = express.Router();

// ============================================
// MOBILE APP VENDOR ENDPOINTS
// ============================================

// Get vendor profile (mobile app)
router.get('/profile', authenticateVendorToken, async (req: any, res) => {
  try {
    const vendor = await db.getVendorById(req.user.vendorId);
    if (!vendor) {
      return res.status(404).json({ error: 'Vendor not found' });
    }

    res.json({
      success: true,
      vendor
    });
  } catch (error) {
    console.error('Get vendor profile error:', error);
    res.status(500).json({ error: 'Failed to get vendor profile' });
  }
});

// Update vendor profile (mobile app)
router.put('/profile', authenticateVendorToken, async (req: any, res) => {
  try {
    const updates = req.body;

    // Remove sensitive fields that shouldn't be updated via this endpoint
    delete updates.id;
    delete updates.user_id;
    delete updates.total_orders;
    delete updates.completed_orders;
    delete updates.cancelled_orders;
    delete updates.rating;
    delete updates.created_at;

    const updatedVendor = await db.updateVendor(req.user.vendorId, updates);

    res.json({
      success: true,
      vendor: updatedVendor
    });
  } catch (error) {
    console.error('Update vendor profile error:', error);
    res.status(500).json({ error: 'Failed to update vendor profile' });
  }
});

// Update vendor location (mobile app)
router.put('/location', authenticateVendorToken, async (req: any, res) => {
  try {
    const { latitude, longitude, address } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: 'Latitude and longitude required' });
    }

    const updatedVendor = await db.updateVendor(req.user.vendorId, {
      latitude,
      longitude,
      address: address || undefined
    });

    res.json({
      success: true,
      vendor: updatedVendor
    });
  } catch (error) {
    console.error('Update vendor location error:', error);
    res.status(500).json({ error: 'Failed to update vendor location' });
  }
});

// Set vacation mode (mobile app)
router.put('/vacation', authenticateVendorToken, async (req: any, res) => {
  try {
    const { isOnVacation, vacationReason, vacationEndDate } = req.body;

    const updates: any = {
      is_on_vacation: isOnVacation
    };

    if (isOnVacation) {
      updates.vacation_reason = vacationReason || null;
      updates.vacation_end_date = vacationEndDate ? new Date(vacationEndDate).toISOString() : null;
    } else {
      updates.vacation_reason = null;
      updates.vacation_end_date = null;
    }

    const updatedVendor = await db.updateVendor(req.user.vendorId, updates);

    res.json({
      success: true,
      vendor: updatedVendor
    });
  } catch (error) {
    console.error('Update vacation mode error:', error);
    res.status(500).json({ error: 'Failed to update vacation mode' });
  }
});

// Get vendor statistics (mobile app)
router.get('/stats', authenticateVendorToken, async (req: any, res) => {
  try {
    const vendorId = req.user.vendorId;

    // Get vendor details
    const vendor = await db.getVendorById(vendorId);
    if (!vendor) {
      return res.status(404).json({ error: 'Vendor not found' });
    }

    // Get today's orders
    const today = new Date().toISOString().split('T')[0];
    const todayOrders = await db.getOrders(vendorId);
    const todayOrdersFiltered = todayOrders.filter(order =>
      order.delivery_date === today && order.status === 'delivered'
    );

    // Get monthly analytics
    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - 1);
    const monthlyAnalytics = await db.getVendorAnalytics(
      vendorId,
      startDate.toISOString().split('T')[0],
      new Date().toISOString().split('T')[0]
    );

    const totalMonthlyRevenue = monthlyAnalytics.reduce((sum, day) => sum + (day.total_revenue || 0), 0);
    const totalMonthlyOrders = monthlyAnalytics.reduce((sum, day) => sum + (day.total_orders || 0), 0);

    res.json({
      success: true,
      stats: {
        totalOrders: vendor.total_orders || 0,
        completedOrders: vendor.completed_orders || 0,
        cancelledOrders: vendor.cancelled_orders || 0,
        rating: vendor.rating || 0.0,
        todayOrders: todayOrdersFiltered.length,
        todayRevenue: todayOrdersFiltered.reduce((sum, order) => sum + (order.total_amount || 0), 0),
        monthlyRevenue: totalMonthlyRevenue,
        monthlyOrders: totalMonthlyOrders,
        isOnVacation: vendor.is_on_vacation || false,
        walletBalance: vendor.wallet_balance || 0
      }
    });
  } catch (error) {
    console.error('Get vendor stats error:', error);
    res.status(500).json({ error: 'Failed to get vendor statistics' });
  }
});

// Get vendor products (mobile app)
router.get('/products', authenticateVendorToken, async (req: any, res) => {
  try {
    const vendorId = req.user.vendorId;
    const products = await db.getVendorProducts(vendorId);

    res.json({
      success: true,
      products
    });
  } catch (error) {
    console.error('Get vendor products error:', error);
    res.status(500).json({ error: 'Failed to get vendor products' });
  }
});

// Update product stock and price (mobile app)
router.put('/products/:productId', authenticateVendorToken, async (req: any, res) => {
  try {
    const { productId } = req.params;
    const { price, stockQuantity, isAvailable } = req.body;

    if (db.isUsingSupabase()) {
      // Update in Supabase
      const { data, error } = await supabaseAdmin
        .from('vendor_products')
        .update({
          price,
          stock_quantity: stockQuantity,
          is_available: isAvailable,
          updated_at: new Date().toISOString()
        })
        .eq('vendor_id', req.user.vendorId)
        .eq('product_id', productId)
        .select()
        .single();

      if (error) {
        return res.status(500).json({ error: error.message });
      }

      res.json({
        success: true,
        product: data
      });
    } else {
      // Development mode - just return success
      res.json({
        success: true,
        message: 'Product updated successfully (development mode)'
      });
    }
  } catch (error) {
    console.error('Update vendor product error:', error);
    res.status(500).json({ error: 'Failed to update product' });
  }
});

// Get vendor orders (mobile app)
router.get('/orders', authenticateVendorToken, async (req: any, res) => {
  try {
    const vendorId = req.user.vendorId;
    const { status, date, limit = 50, offset = 0 } = req.query;

    let orders = await db.getOrders(vendorId, status as string);

    // Filter by date if provided
    if (date) {
      orders = orders.filter(order => order.delivery_date === date);
    }

    // Apply pagination
    const paginatedOrders = orders.slice(
      parseInt(offset as string),
      parseInt(offset as string) + parseInt(limit as string)
    );

    res.json({
      success: true,
      orders: paginatedOrders,
      total: orders.length,
      hasMore: orders.length > parseInt(offset as string) + parseInt(limit as string)
    });
  } catch (error) {
    console.error('Get vendor orders error:', error);
    res.status(500).json({ error: 'Failed to get vendor orders' });
  }
});

// Get daily summary (mobile app)
router.get('/daily-summary', authenticateVendorToken, async (req: any, res) => {
  try {
    const vendorId = req.user.vendorId;
    const date = req.query.date as string || new Date().toISOString().split('T')[0];

    const orders = await db.getOrdersByDateRange(vendorId, date, date);
    const deliveredOrders = orders.filter(order => order.status === 'delivered');
    const pendingOrders = orders.filter(order => order.status === 'pending');

    const totalCans = orders.reduce((sum, order) => {
      // This would need order items for accurate can count
      return sum + 1; // Simplified
    }, 0);

    const totalEarnings = deliveredOrders.reduce((sum, order) => sum + (order.total_amount || 0), 0);

    res.json({
      success: true,
      date,
      summary: {
        totalOrders: orders.length,
        deliveredOrders: deliveredOrders.length,
        pendingOrders: pendingOrders.length,
        totalCans,
        totalEarnings,
        averageOrderValue: deliveredOrders.length > 0 ? totalEarnings / deliveredOrders.length : 0
      }
    });
  } catch (error) {
    console.error('Get daily summary error:', error);
    res.status(500).json({ error: 'Failed to get daily summary' });
  }
});

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