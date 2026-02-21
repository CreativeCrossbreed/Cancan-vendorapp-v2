import express from 'express';
import { supabase } from '../config/database';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Get all customers with pagination and filtering
router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const search = req.query.search as string;

    let query = supabase
      .from('customers')
      .select('*', { count: 'exact' })
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (search) {
      query = query.or(`name.ilike.%${search}%,phone.ilike.%${search}%,address.ilike.%${search}%`);
    }

    const { data: customers, error, count } = await query;

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    // Get order stats for each customer
    const customerIds = customers?.map(c => c.id) || [];
    const { data: orderStats } = await supabase
      .from('orders')
      .select('customer_id, status, total_amount')
      .in('customer_id', customerIds);

    const statsMap = orderStats?.reduce((acc: any, stat: any) => {
      if (!acc[stat.customer_id]) {
        acc[stat.customer_id] = {
          totalOrders: 0,
          completedOrders: 0,
          totalSpent: 0,
          lastOrderDate: null,
        };
      }
      acc[stat.customer_id].totalOrders++;
      if (stat.status === 'completed') {
        acc[stat.customer_id].completedOrders++;
        acc[stat.customer_id].totalSpent += stat.total_amount;
      }
      return acc;
    }, {});

    // Get last order date for each customer
    const { data: lastOrders } = await supabase
      .from('orders')
      .select('customer_id, created_at')
      .in('customer_id', customerIds)
      .order('created_at', { ascending: false });

    lastOrders?.forEach(order => {
      if (!statsMap[order.customer_id].lastOrderDate) {
        statsMap[order.customer_id].lastOrderDate = order.created_at;
      }
    });

    const customersWithStats = customers?.map(customer => ({
      ...customer,
      stats: statsMap?.[customer.id] || {
        totalOrders: 0,
        completedOrders: 0,
        totalSpent: 0,
        lastOrderDate: null,
      },
    }));

    res.json({
      customers: customersWithStats,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get customer by ID
router.get('/:id', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;

    const { data: customer, error } = await supabase
      .from('customers')
      .select('*')
      .eq('id', id)
      .single();

    if (error) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // Get customer's orders
    const { data: orders } = await supabase
      .from('orders')
      .select(`
        *,
        vendor:vendors(name),
        order_items(
          *,
          product:products(name)
        )
      `)
      .eq('customer_id', id)
      .order('created_at', { ascending: false });

    res.json({
      customer,
      orders: orders || [],
    });
  } catch (error) {
    console.error('Get customer error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create new customer
router.post('/', authenticateToken, async (req: any, res) => {
  try {
    const {
      name,
      phone,
      address,
      flat_number,
      floor,
      building_name,
    } = req.body;

    if (!name || !phone || !address) {
      return res.status(400).json({ error: 'Name, phone, and address are required' });
    }

    const { data: customer, error } = await supabase
      .from('customers')
      .insert([{
        name,
        phone,
        address,
        flat_number,
        floor,
        building_name,
      }])
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.status(201).json(customer);
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update customer
router.put('/:id', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      phone,
      address,
      flat_number,
      floor,
      building_name,
      status,
    } = req.body;

    const updateData: any = {};
    if (name !== undefined) updateData.name = name;
    if (phone !== undefined) updateData.phone = phone;
    if (address !== undefined) updateData.address = address;
    if (flat_number !== undefined) updateData.flat_number = flat_number;
    if (floor !== undefined) updateData.floor = floor;
    if (building_name !== undefined) updateData.building_name = building_name;
    if (status !== undefined) updateData.status = status;

    const { data: customer, error } = await supabase
      .from('customers')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    if (!customer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    res.json(customer);
  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get customer analytics
router.get('/:id/analytics', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;
    const { period = '30' } = req.query; // days

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(period));

    // Get order history
    const { data: orders } = await supabase
      .from('orders')
      .select('status, total_amount, created_at, vendor:vendors(name)')
      .eq('customer_id', id)
      .gte('created_at', startDate.toISOString())
      .order('created_at', { ascending: false });

    // Get favorite products
    const { data: favoriteProducts } = await supabase
      .from('order_items')
      .select(`
        quantity,
        subtotal,
        product:products(name)
      `)
      .in('order_id', orders?.map(o => o.id) || []);

    // Calculate analytics
    const analytics = {
      totalOrders: orders?.length || 0,
      completedOrders: orders?.filter(o => o.status === 'completed').length || 0,
      cancelledOrders: orders?.filter(o => o.status === 'cancelled').length || 0,
      totalSpent: orders?.filter(o => o.status === 'completed').reduce((sum, o) => sum + o.total_amount, 0) || 0,
      averageOrderValue: 0,
      mostOrderedVendor: null as any,
      favoriteProducts: favoriteProducts?.reduce((acc: any, item: any) => {
        const productName = item.product?.name || 'Unknown';
        if (!acc[productName]) {
          acc[productName] = { name: productName, quantity: 0, totalSpent: 0 };
        }
        acc[productName].quantity += item.quantity;
        acc[productName].totalSpent += item.subtotal;
        return acc;
      }, {}),
    };

    // Calculate average order value
    if (analytics.completedOrders > 0) {
      analytics.averageOrderValue = analytics.totalSpent / analytics.completedOrders;
    }

    // Find most ordered vendor
    const vendorCounts = orders?.reduce((acc: any, order: any) => {
      const vendorName = order.vendor?.name || 'Unknown';
      acc[vendorName] = (acc[vendorName] || 0) + 1;
      return acc;
    }, {});

    if (vendorCounts) {
      const mostOrdered = Object.entries(vendorCounts).reduce((a: any, b: any) =>
        vendorCounts[a[0] as string] > vendorCounts[b[0] as string] ? a : b
      );
      analytics.mostOrderedVendor = { name: mostOrdered[0], orders: mostOrdered[1] };
    }

    res.json(analytics);
  } catch (error) {
    console.error('Get customer analytics error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;