import express from 'express';
import axios from 'axios';
import { supabase } from '../config/database';
import { authenticateToken } from '../middleware/auth';

const router = express.Router();

// WhatsApp API configuration
const WHATSAPP_API_URL = 'https://graph.facebook.com/v18.0';
const WHATSAPP_TOKEN = process.env.WHATSAPP_API_TOKEN;
const PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID;

// Webhook verification
router.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode && token) {
    if (mode === 'subscribe' && token === process.env.WHATSAPP_WEBHOOK_SECRET) {
      console.log('Webhook verified');
      res.status(200).send(challenge);
    } else {
      res.sendStatus(403);
    }
  }
});

// Webhook endpoint for incoming messages
router.post('/webhook', async (req, res) => {
  try {
    const data = req.body;

    // Check if it's a message from WhatsApp
    if (data.object === 'whatsapp_business_account') {
      for (const entry of data.entry) {
        for (const change of entry.changes) {
          if (change.field === 'messages') {
            const messages = change.value.messages;
            if (messages && messages.length > 0) {
              for (const message of messages) {
                await processIncomingMessage(message);
              }
            }
          }
        }
      }

      // Send 200 OK response
      res.status(200).send('EVENT_RECEIVED');
    } else {
      res.sendStatus(404);
    }
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).send('Internal server error');
  }
});

// Process incoming message
async function processIncomingMessage(message: any) {
  try {
    if (message.type !== 'text') return;

    const from = message.from; // Customer phone number
    const messageId = message.id;
    const text = message.text.body.toLowerCase();
    const timestamp = new Date().toISOString();

    // Save message to database
    await supabase.from('whatsapp_messages').insert([{
      message_id: messageId,
      customer_phone: from,
      message_type: message.type,
      message_content: message.text.body,
      direction: 'inbound',
      status: 'received',
      created_at: timestamp,
    }]);

    // Check if this is an order
    const orderDetection = detectOrder(text);
    if (orderDetection.isOrder) {
      await handleOrderRequest(from, messageId, orderDetection, timestamp);
    } else {
      // Send help message
      await sendHelpMessage(from);
    }
  } catch (error) {
    console.error('Process message error:', error);
  }
}

// Detect if message is an order
function detectOrder(text: string) {
  const orderKeywords = ['order', 'need', 'want', 'deliver', 'can', 'water', 'jar', 'bottle'];
  const isOrder = orderKeywords.some(keyword => text.includes(keyword));

  // Extract quantity (numbers)
  const quantityMatch = text.match(/\d+/);
  const quantity = quantityMatch ? parseInt(quantityMatch[0]) : 1;

  // Detect product type
  let product = 'Water Can'; // Default
  if (text.includes('20 liter') || text.includes('20l')) product = '20 Liter Water Can';
  if (text.includes('10 liter') || text.includes('10l')) product = '10 Liter Water Can';
  if (text.includes('5 liter') || text.includes('5l')) product = '5 Liter Water Can';

  return {
    isOrder,
    quantity,
    product,
    confidence: isOrder ? (quantityMatch ? 0.9 : 0.7) : 0.1,
  };
}

// Handle order request
async function handleOrderRequest(
  customerPhone: string,
  messageId: string,
  orderDetection: any,
  timestamp: string
) {
  try {
    // Find or create customer
    let { data: customer, error: customerError } = await supabase
      .from('customers')
      .select('id, name')
      .eq('phone', customerPhone)
      .single();

    if (customerError || !customer) {
      // Customer not found, ask for registration
      await sendMessage(customerPhone,
        "Welcome to Can Can! To place an order, please register first by providing:\n" +
        "1. Your full name\n" +
        "2. Your complete delivery address\n\n" +
        "Example: My name is John Doe and I live at 123 Main Street, Apartment 4B"
      );
      return;
    }

    // Find available vendor
    const { data: availableVendor } = await supabase
      .from('vendors')
      .select('id, name')
      .eq('status', 'active')
      .eq('is_on_vacation', false)
      .limit(1)
      .single();

    if (!availableVendor) {
      await sendMessage(customerPhone,
        "Sorry, no vendors are available at the moment. Please try again later."
      );
      return;
    }

    // Create WhatsApp order record
    const { data: whatsappOrder, error: whatsappOrderError } = await supabase
      .from('whatsapp_orders')
      .insert([{
        message_id: messageId,
        customer_id: customer.id,
        parsed_quantity: orderDetection.quantity,
        parsed_product: orderDetection.product,
        status: 'pending_assignment',
        assigned_vendor_id: availableVendor.id,
        created_at: timestamp,
      }])
      .select()
      .single();

    if (whatsappOrderError) {
      console.error('Error creating WhatsApp order:', whatsappOrderError);
      await sendMessage(customerPhone,
        "Sorry, there was an error processing your order. Please try again."
      );
      return;
    }

    // Create actual order
    const order_number = `WA${Date.now()}`;
    const delivery_date = new Date();
    delivery_date.setDate(delivery_date.getDate() + 1); // Next day delivery
    const time_slot = 'Morning (9AM - 12PM)'; // Default time slot

    // Get product or create default
    const { data: product } = await supabase
      .from('products')
      .select('id')
      .eq('name', orderDetection.product)
      .single();

    if (!product) {
      await sendMessage(customerPhone,
        "Sorry, the requested product is not available. Please try with 'Water Can'."
      );
      return;
    }

    // Get vendor product pricing
    const { data: vendorProduct } = await supabase
      .from('vendor_products')
      .select('selling_price')
      .eq('vendor_id', availableVendor.id)
      .eq('product_id', product.id)
      .single();

    if (!vendorProduct) {
      await sendMessage(customerPhone,
        "Sorry, the vendor doesn't have this product available. Please try again."
      );
      return;
    }

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert([{
        order_number,
        vendor_id: availableVendor.id,
        customer_id: customer.id,
        delivery_date: delivery_date.toISOString().split('T')[0],
        time_slot,
        total_amount: orderDetection.quantity * vendorProduct.selling_price,
        status: 'pending',
        is_delivered: false,
        payment_status: 'unpaid',
        notes: `Order via WhatsApp: ${orderDetection.quantity} x ${orderDetection.product}`,
      }])
      .select()
      .single();

    if (orderError) {
      console.error('Error creating order:', orderError);
      await sendMessage(customerPhone,
        "Sorry, there was an error creating your order. Please try again."
      );
      return;
    }

    // Create order items
    await supabase.from('order_items').insert([{
      order_id: order.id,
      product_id: product.id,
      quantity: orderDetection.quantity,
      unit_price: vendorProduct.selling_price,
      subtotal: orderDetection.quantity * vendorProduct.selling_price,
    }]);

    // Update WhatsApp order status
    await supabase
      .from('whatsapp_orders')
      .update({ status: 'assigned' })
      .eq('id', whatsappOrder.id);

    // Send confirmation message
    const confirmationMessage =
      `✅ Order Confirmed!\n\n` +
      `Order Number: ${order_number}\n` +
      `Item: ${orderDetection.quantity} x ${orderDetection.product}\n` +
      `Total Amount: ₹${orderDetection.quantity * vendorProduct.selling_price}\n` +
      `Delivery Date: ${delivery_date.toLocaleDateString()}\n` +
      `Time Slot: ${time_slot}\n\n` +
      `Vendor: ${availableVendor.name}\n\n` +
      `You will receive updates when your order is on the way!`;

    await sendMessage(customerPhone, confirmationMessage);

  } catch (error) {
    console.error('Handle order request error:', error);
  }
}

// Send help message
async function sendHelpMessage(to: string) {
  const helpMessage =
    "🤖 Can Can Water Delivery Assistant\n\n" +
    "To place an order, send a message like:\n" +
    "• \"I need 2 water cans\"\n" +
    "• \"Order 1 20 liter water can\"\n" +
    "• \"Deliver 3 water jars\"\n\n" +
    "For support, call our helpline.";

  await sendMessage(to, helpMessage);
}

// Send message via WhatsApp API
async function sendMessage(to: string, message: string) {
  try {
    if (!WHATSAPP_TOKEN || !PHONE_NUMBER_ID) {
      console.error('WhatsApp credentials not configured');
      return;
    }

    const url = `${WHATSAPP_API_URL}/${PHONE_NUMBER_ID}/messages`;
    const data = {
      messaging_product: 'whatsapp',
      to: to,
      type: 'text',
      text: {
        body: message,
      },
    };

    const config = {
      headers: {
        'Authorization': `Bearer ${WHATSAPP_TOKEN}`,
        'Content-Type': 'application/json',
      },
    };

    const response = await axios.post(url, data, config);

    // Save outbound message
    await supabase.from('whatsapp_messages').insert([{
      message_id: response.data.messages[0].id,
      customer_phone: to,
      message_type: 'text',
      message_content: message,
      direction: 'outbound',
      status: 'sent',
      created_at: new Date().toISOString(),
    }]);

    return response.data;
  } catch (error) {
    console.error('Send message error:', error);
    throw error;
  }
}

// Admin routes for WhatsApp management

// Get WhatsApp configuration
router.get('/config', authenticateToken, async (req: any, res) => {
  try {
    const { data: config, error } = await supabase
      .from('whatsapp_config')
      .select('*')
      .eq('is_active', true)
      .single();

    if (error) {
      return res.status(404).json({ error: 'WhatsApp configuration not found' });
    }

    // Don't expose sensitive data
    const safeConfig = {
      phone_number_id: config.phone_number_id,
      business_account_id: config.business_account_id,
      is_active: config.is_active,
      created_at: config.created_at,
    };

    res.json(safeConfig);
  } catch (error) {
    console.error('Get WhatsApp config error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get WhatsApp messages
router.get('/messages', authenticateToken, async (req: any, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const direction = req.query.direction as string;

    let query = supabase
      .from('whatsapp_messages')
      .select('*', { count: 'exact' })
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (direction) {
      query = query.eq('direction', direction);
    }

    const { data: messages, error, count } = await query;

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json({
      messages,
      pagination: {
        page,
        limit,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / limit),
      },
    });
  } catch (error) {
    console.error('Get WhatsApp messages error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get WhatsApp orders
router.get('/orders', authenticateToken, async (req: any, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status as string;

    let query = supabase
      .from('whatsapp_orders')
      .select(`
        *,
        customer:customers(name, phone),
        assigned_vendor:vendors(name, business_name)
      `, { count: 'exact' })
      .range((page - 1) * limit, page * limit - 1)
      .order('created_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

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
    console.error('Get WhatsApp orders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Send custom message
router.post('/send', authenticateToken, async (req: any, res) => {
  try {
    const { to, message } = req.body;

    if (!to || !message) {
      return res.status(400).json({ error: 'Phone number and message are required' });
    }

    const result = await sendMessage(to, message);
    res.json({ success: true, messageId: result.messages[0].id });
  } catch (error) {
    console.error('Send custom message error:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

export default router;