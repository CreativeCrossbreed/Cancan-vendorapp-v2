import express from 'express';
import { supabase } from '../config/database';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// Get all orders with pagination and filtering
router.get('/', authenticateToken, async (req: any, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status as string;
    const payment_status = req.query.payment_status as string;
    const vendor_id = req.query.vendor_id as string;
    const customer_id = req.query.customer_id as string;
    const date_from = req.query.date_from as string;
    const date_to = req.query.date_to as string;

    let query = supabase
      .from('orders')
      .select(`
        *,
        customer:customers(name, phone, address),
        vendor:vendors(name, business_name),
        order_items(
          *,
          product:products(name)
        )
      `, { count: 'exact' })
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (status) query = query.eq('status', status);
    if (payment_status) query = query.eq('payment_status', payment_status);
    if (vendor_id) query = query.eq('vendor_id', vendor_id);
    if (customer_id) query = query.eq('customer_id', customer_id);
    if (date_from) query = query.gte('delivery_date', date_from);
    if (date_to) query = query.lte('delivery_date', date_to);

    const { data: orders, error, count } = await query;

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json({
      orders,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get order by ID
router.get('/:id', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;

    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        *,
        customer:customers(*),
        vendor:vendors(*),
        order_items(
          *,
          product:products(*)
        )
      `)
      .eq('id', id)
      .single();

    if (error) {
      return res.status(404).json({ error: 'Order not found' });
    }

    res.json(order);
  } catch (error) {
    console.error('Get order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update order status
router.put('/:id/status', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;
    const { status, notes, cancellation_reason } = req.body;

    const updateData: any = { status };
    if (notes !== undefined) updateData.notes = notes;
    if (cancellation_reason !== undefined) updateData.cancellation_reason = cancellation_reason;
    if (status === 'completed') updateData.is_delivered = true;
    if (status === 'completed' && !updateData.delivered_at) {
      updateData.delivered_at = new Date().toISOString();
    }

    const { data: order, error } = await supabase
      .from('orders')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json(order);
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update payment status
router.put('/:id/payment', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;
    const { payment_status } = req.body;

    const updateData: any = { payment_status };
    if (payment_status === 'paid' && !updateData.payment_marked_at) {
      updateData.payment_marked_at = new Date().toISOString();
    }

    const { data: order, error } = await supabase
      .from('orders')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json(order);
  } catch (error) {
    console.error('Update payment status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Assign order to vendor
router.put('/:id/assign', authenticateToken, async (req: any, res) => {
  try {
    const { id } = req.params;
    const { vendor_id } = req.body;

    if (!vendor_id) {
      return res.status(400).json({ error: 'Vendor ID is required' });
    }

    // Check if vendor exists and is active
    const { data: vendor, error: vendorError } = await supabase
      .from('vendors')
      .select('id, status, is_on_vacation')
      .eq('id', vendor_id)
      .single();

    if (vendorError || !vendor) {
      return res.status(404).json({ error: 'Vendor not found' });
    }

    if (vendor.status !== 'active' || vendor.is_on_vacation) {
      return res.status(400).json({ error: 'Vendor is not available for assignments' });
    }

    const { data: order, error } = await supabase
      .from('orders')
      .update({ vendor_id })
      .eq('id', id)
      .select(`
        *,
        customer:customers(name, phone),
        vendor:vendors(name, phone)
      `)
      .single();

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    // TODO: Send notification to vendor via WebSocket

    res.json(order);
  } catch (error) {
    console.error('Assign order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create manual order
router.post('/', authenticateToken, async (req: any, res) => {
  try {
    const {
      customer_id,
      vendor_id,
      delivery_date,
      time_slot,
      notes,
      order_items,
    } = req.body;

    if (!customer_id || !vendor_id || !delivery_date || !time_slot || !order_items) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Validate customer and vendor exist
    const { data: customer } = await supabase
      .from('customers')
      .select('id')
      .eq('id', customer_id)
      .single();

    const { data: vendor } = await supabase
      .from('vendors')
      .select('id')
      .eq('id', vendor_id)
      .single();

    if (!customer || !vendor) {
      return res.status(400).json({ error: 'Invalid customer or vendor' });
    }

    // Generate order number
    const order_number = `ORD${Date.now()}`;

    // Calculate total amount
    const total_amount = order_items.reduce((sum: number, item: any) => {
      return sum + (item.quantity * item.unit_price);
    }, 0);

    // Create order
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert([{
        order_number,
        customer_id,
        vendor_id,
        delivery_date,
        time_slot,
        total_amount,
        status: 'pending',
        is_delivered: false,
        payment_status: 'unpaid',
        notes,
      }])
      .select()
      .single();

    if (orderError) {
      return res.status(400).json({ error: orderError.message });
    }

    // Create order items
    const orderItemsToInsert = order_items.map((item: any) => ({
      order_id: order.id,
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      subtotal: item.quantity * item.unit_price,
    }));

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItemsToInsert);

    if (itemsError) {
      // Rollback order creation
      await supabase.from('orders').delete().eq('id', order.id);
      return res.status(400).json({ error: itemsError.message });
    }

    res.status(201).json(order);
  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get today's orders
router.get('/today/all', authenticateToken, async (req: any, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    const { data: orders, error } = await supabase
      .from('orders')
      .select(`
        *,
        customer:customers(name, phone),
        vendor:vendors(name, business_name),
        order_items(
          *,
          product:products(name)
        )
      `)
      .eq('delivery_date', today)
      .order('time_slot');

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    const groupedOrders = orders?.reduce((acc: any, order: any) => {
      const timeSlot = order.time_slot;
      if (!acc[timeSlot]) {
        acc[timeSlot] = [];
      }
      acc[timeSlot].push(order);
      return acc;
    }, {});

    res.json({
      date: today,
      groupedOrders,
      totalOrders: orders?.length || 0,
    });
  } catch (error) {
    console.error('Get today\'s orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;