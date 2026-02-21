import express from 'express';
import crypto from 'crypto';
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
  const appSecret = process.env.META_APP_SECRET || process.env.WHATSAPP_APP_SECRET;
  const signature = req.headers['x-hub-signature-256'] as string | undefined;
  if (appSecret && signature) {
    const raw = (req as any).rawBody as Buffer | undefined;
    if (!raw) return res.sendStatus(400);
    const hmac = crypto.createHmac('sha256', appSecret).update(raw).digest('hex');
    const expected = `sha256=${hmac}`;
    const ok = expected.length === signature.length && crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
    if (!ok) return res.sendStatus(401);
  }
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
    const text = message.text.body.toLowerCase().trim();
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

    // Check if customer has an active session
    const { data: activeSession } = await supabase
      .from('whatsapp_sessions')
      .select('*')
      .eq('customer_phone', from)
      .eq('status', 'active')
      .single();

    if (activeSession) {
      // Handle based on session state
      await handleSessionMessage(from, text, activeSession);
      return;
    }

    // Check if this is an order initiation
    const orderDetection = detectOrder(text);
    if (orderDetection.isOrder) {
      await initiateOrderFlow(from, messageId, text, timestamp);
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

// Initiate enhanced order flow
async function initiateOrderFlow(
  customerPhone: string,
  messageId: string,
  messageText: string,
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

    // Find available vendors in customer's area
    const { data: availableVendors, error: vendorError } = await supabase
      .from('vendors')
      .select('id, name, business_name, phone, service_areas')
      .eq('status', 'active')
      .eq('is_on_vacation', false)
      .limit(3);

    if (vendorError || !availableVendors || availableVendors.length === 0) {
      await sendMessage(customerPhone,
        "Sorry, no vendors are available in your area at the moment. Please try again later."
      );
      return;
    }

    // Create WhatsApp session
    const { data: session, error: sessionError } = await supabase
      .from('whatsapp_sessions')
      .insert([{
        customer_phone: customerPhone,
        customer_id: customer.id,
        session_state: 'vendor_confirmation',
        session_data: {
          original_message: messageText,
          vendors: availableVendors
        },
        status: 'active',
        created_at: timestamp,
        updated_at: timestamp,
      }])
      .select()
      .single();

    if (sessionError) {
      console.error('Error creating session:', sessionError);
      await sendMessage(customerPhone,
        "Sorry, there was an error starting your order. Please try again."
      );
      return;
    }

    // Send vendor confirmation message
    let vendorMessage = `🤖 Can Can Water Delivery\n\n`;
    vendorMessage += `We found available vendors for your order:\n\n`;

    availableVendors.forEach((vendor, index) => {
      vendorMessage += `${index + 1}. ${vendor.name} (${vendor.business_name})\n`;
    });

    vendorMessage += `\nPlease reply with the vendor number (1-${availableVendors.length}) to confirm:`;

    await sendMessage(customerPhone, vendorMessage);

  } catch (error) {
    console.error('Initiate order flow error:', error);
  }
}

// Handle messages within an active session
async function handleSessionMessage(
  customerPhone: string,
  messageText: string,
  session: any
) {
  try {
    const sessionState = session.session_state;
    const sessionData = session.session_data;

    switch (sessionState) {
      case 'vendor_confirmation':
        await handleVendorSelection(customerPhone, messageText, session);
        break;
      case 'inventory_display':
        await handleInventorySelection(customerPhone, messageText, session);
        break;
      case 'additional_items':
        await handleAdditionalItems(customerPhone, messageText, session);
        break;
      case 'order_confirmation':
        await handleOrderConfirmation(customerPhone, messageText, session);
        break;
      default:
        await sendHelpMessage(customerPhone);
        break;
    }
  } catch (error) {
    console.error('Handle session message error:', error);
  }
}

// Handle vendor selection
async function handleVendorSelection(customerPhone: string, messageText: string, session: any) {
  const vendorNumber = parseInt(messageText);
  const vendors = session.session_data.vendors;

  if (isNaN(vendorNumber) || vendorNumber < 1 || vendorNumber > vendors.length) {
    await sendMessage(customerPhone,
      `Please enter a valid vendor number (1-${vendors.length}):`
    );
    return;
  }

  const selectedVendor = vendors[vendorNumber - 1];

  // Update session with selected vendor
  await supabase
    .from('whatsapp_sessions')
    .update({
      current_vendor_id: selectedVendor.id,
      session_state: 'inventory_display',
      session_data: {
        ...session.session_data,
        selected_vendor: selectedVendor,
        selected_vendor_number: vendorNumber
      },
      updated_at: new Date().toISOString()
    })
    .eq('id', session.id);

  // Get vendor inventory
  const { data: vendorProducts, error: productError } = await supabase
    .from('vendor_products')
    .select(`
      products:product_id(id, name, sku),
      selling_price,
      stock_quantity
    `)
    .eq('vendor_id', selectedVendor.id)
    .gt('stock_quantity', 0)
    .order('stock_quantity', { ascending: false });

  if (productError || !vendorProducts || vendorProducts.length === 0) {
    await sendMessage(customerPhone,
      "Sorry, this vendor has no products available at the moment. Please try another vendor."
    );
    return;
  }

  // Display inventory
  let inventoryMessage = `📦 ${selectedVendor.name} - Available Inventory\n\n`;

  vendorProducts.forEach((product, index) => {
    inventoryMessage += `${index + 1}. ${product.products.name} (${product.products.sku})\n`;
    inventoryMessage += `   Available: ${product.stock_quantity} units\n`;
    inventoryMessage += `   Price: ₹${product.selling_price} each\n\n`;
  });

  inventoryMessage += `Please reply with the item number and quantity:\n`;
  inventoryMessage += `Example: "2 3" for 3 units of item #2\n\n`;
  inventoryMessage += `Type "done" when finished adding items.`;

  await sendMessage(customerPhone, inventoryMessage);

  // Reserve inventory for this session (15 minute timeout)
  const expiresAt = new Date();
  expiresAt.setMinutes(expiresAt.getMinutes() + 15);

  const reservations = vendorProducts.map(product => ({
    session_id: session.id,
    vendor_id: selectedVendor.id,
    product_id: product.products.id,
    quantity_reserved: Math.min(10, product.stock_quantity), // Reserve max 10 units per product
    expires_at: expiresAt.toISOString(),
    status: 'reserved'
  }));

  await supabase.from('whatsapp_reservations').insert(reservations);
}

// Handle inventory selection
async function handleInventorySelection(customerPhone: string, messageText: string, session: any) {
  const text = messageText.trim();

  if (text === 'done') {
    // Move to order confirmation
    await proceedToOrderConfirmation(customerPhone, session);
    return;
  }

  // Parse selection (format: "itemNumber quantity")
  const match = text.match(/^(\d+)\s+(\d+)$/);
  if (!match) {
    await sendMessage(customerPhone,
      "Invalid format. Please use format: 'itemNumber quantity'\n" +
      "Example: '2 3' for 3 units of item #2\n\n" +
      "Type 'done' when finished adding items."
    );
    return;
  }

  const itemNumber = parseInt(match[1]);
  const quantity = parseInt(match[2]);

  // Get vendor inventory
  const { data: vendorProducts, error: productError } = await supabase
    .from('vendor_products')
    .select(`
      products:product_id(id, name, sku),
      selling_price,
      stock_quantity
    `)
    .eq('vendor_id', session.current_vendor_id)
    .gt('stock_quantity', 0)
    .order('stock_quantity', { ascending: false });

  if (productError || !vendorProducts || itemNumber < 1 || itemNumber > vendorProducts.length) {
    await sendMessage(customerPhone,
      "Invalid item number. Please check the inventory list and try again."
    );
    return;
  }

  const selectedProduct = vendorProducts[itemNumber - 1];

  // Check if enough stock is available
  const { data: reservation, error: reservationError } = await supabase
    .from('whatsapp_reservations')
    .select('*')
    .eq('session_id', session.id)
    .eq('product_id', selectedProduct.products.id)
    .eq('status', 'reserved')
    .single();

  if (reservationError || !reservation || reservation.quantity_reserved < quantity) {
    await sendMessage(customerPhone,
      `Sorry, only ${reservation ? reservation.quantity_reserved : 0} units of ${selectedProduct.products.name} are available.\n` +
      `Please try with a lower quantity or choose another item.`
    );
    return;
  }

  // Update reservation with actual quantity
  await supabase
    .from('whatsapp_reservations')
    .update({
      quantity_reserved: quantity,
      status: 'confirmed'
    })
    .eq('id', reservation.id);

  // Update session data
  const currentItems = session.session_data.selected_items || [];
  const existingItemIndex = currentItems.findIndex(item => item.product_id === selectedProduct.products.id);

  if (existingItemIndex >= 0) {
    currentItems[existingItemIndex].quantity = quantity;
  } else {
    currentItems.push({
      product_id: selectedProduct.products.id,
      product_name: selectedProduct.products.name,
      quantity: quantity,
      unit_price: selectedProduct.selling_price,
      subtotal: quantity * selectedProduct.selling_price
    });
  }

  await supabase
    .from('whatsapp_sessions')
    .update({
      session_data: {
        ...session.session_data,
        selected_items: currentItems
      },
      updated_at: new Date().toISOString()
    })
    .eq('id', session.id);

  // Confirm selection
  const confirmationMessage = `✅ Added ${quantity} x ${selectedProduct.products.name} to your order\n\n`;
  confirmationMessage += `Would you like to add more items?\n\n`;
  confirmationMessage += `1. Yes, add more items\n`;
  confirmationMessage += `2. No, proceed to checkout`;

  await sendMessage(customerPhone, confirmationMessage);

  // Update session state
  await supabase
    .from('whatsapp_sessions')
    .update({
      session_state: 'additional_items',
      updated_at: new Date().toISOString()
    })
    .eq('id', session.id);
}

// Handle additional items question
async function handleAdditionalItems(customerPhone: string, messageText: string, session: any) {
  const response = messageText.trim();

  if (response === '1' || response.toLowerCase().includes('yes')) {
    // Return to inventory display
    await supabase
      .from('whatsapp_sessions')
      .update({
        session_state: 'inventory_display',
        updated_at: new Date().toISOString()
      })
      .eq('id', session.id);

    await handleVendorSelection(customerPhone, session.session_data.selected_vendor_number.toString(), session);
  } else if (response === '2' || response.toLowerCase().includes('no')) {
    // Proceed to order confirmation
    await proceedToOrderConfirmation(customerPhone, session);
  } else {
    await sendMessage(customerPhone,
      "Please reply with:\n" +
      "1. Yes, add more items\n" +
      "2. No, proceed to checkout"
    );
  }
}

// Proceed to order confirmation
async function proceedToOrderConfirmation(customerPhone: string, session: any) {
  const selectedItems = session.session_data.selected_items || [];
  const selectedVendor = session.session_data.selected_vendor;

  if (selectedItems.length === 0) {
    await sendMessage(customerPhone,
      "Your cart is empty. Please add at least one item to proceed.\n\n" +
      "Type the item number and quantity (e.g., '2 3') to add items."
    );
    return;
  }

  // Calculate total
  const totalAmount = selectedItems.reduce((sum: number, item: any) => sum + item.subtotal, 0);

  // Display order summary
  let summaryMessage = `📋 Order Summary\n\n`;
  summaryMessage += `Vendor: ${selectedVendor.name}\n\n`;
  summaryMessage += `Items:\n`;

  selectedItems.forEach((item: any, index: number) => {
    summaryMessage += `${index + 1}. ${item.product_name} x ${item.quantity} = ₹${item.subtotal}\n`;
  });

  summaryMessage += `\nTotal Amount: ₹${totalAmount}\n\n`;
  summaryMessage += `📍 Delivery Address:\n`;
  summaryMessage += `[Please confirm your delivery address]\n\n`;
  summaryMessage += `Please reply:\n`;
  summaryMessage += `"confirm" to place this order\n`;
  summaryMessage += `"cancel" to cancel this order\n`;
  summaryMessage += `"change" to modify your address`;

  await sendMessage(customerPhone, summaryMessage);

  // Update session state
  await supabase
    .from('whatsapp_sessions')
    .update({
      session_state: 'order_confirmation',
      session_data: {
        ...session.session_data,
        total_amount: totalAmount
      },
      updated_at: new Date().toISOString()
    })
    .eq('id', session.id);
}

// Handle order confirmation
async function handleOrderConfirmation(customerPhone: string, messageText: string, session: any) {
  const response = messageText.trim().toLowerCase();

  if (response === 'confirm') {
    await createFinalOrder(customerPhone, session);
  } else if (response === 'cancel') {
    await cancelOrder(customerPhone, session);
  } else if (response === 'change') {
    await sendMessage(customerPhone,
      "Please provide your delivery address:\n\n" +
      "Example: 123 Main Street, Apartment 4B, Near Landmark, City - 123456"
    );
  } else {
    await sendMessage(customerPhone,
      "Please reply with:\n" +
      "\"confirm\" to place this order\n" +
      "\"cancel\" to cancel this order\n" +
      "\"change\" to modify your address"
    );
  }
}

// Create the final order
async function createFinalOrder(customerPhone: string, session: any) {
  try {
    const selectedItems = session.session_data.selected_items;
    const selectedVendor = session.session_data.selected_vendor;
    const totalAmount = session.session_data.total_amount;

    // Create order
    const order_number = `WA${Date.now()}`;
    const delivery_date = new Date();
    delivery_date.setDate(delivery_date.getDate() + 1); // Next day delivery
    const time_slot = 'Morning (9AM - 12PM)';

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert([{
        order_number,
        vendor_id: selectedVendor.id,
        customer_id: session.customer_id,
        delivery_date: delivery_date.toISOString().split('T')[0],
        time_slot,
        total_amount: totalAmount,
        status: 'pending',
        is_delivered: false,
        payment_status: 'unpaid',
        notes: `Order via WhatsApp - Session ${session.id}`,
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
    const orderItems = selectedItems.map((item: any) => ({
      order_id: order.id,
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      subtotal: item.subtotal,
    }));

    await supabase.from('order_items').insert(orderItems);

    // Clean up reservations
    await supabase
      .from('whatsapp_reservations')
      .update({ status: 'fulfilled' })
      .eq('session_id', session.id);

    // Close session
    await supabase
      .from('whatsapp_sessions')
      .update({
        status: 'completed',
        updated_at: new Date().toISOString()
      })
      .eq('id', session.id);

    // Send confirmation
    let confirmationMessage = `✅ Order Placed Successfully!\n\n`;
    confirmationMessage += `Order Number: ${order_number}\n`;
    confirmationMessage += `Vendor: ${selectedVendor.name}\n\n`;
    confirmationMessage += `Items:\n`;

    selectedItems.forEach((item: any, index: number) => {
      confirmationMessage += `${index + 1}. ${item.product_name} x ${item.quantity}\n`;
    });

    confirmationMessage += `\nTotal Amount: ₹${totalAmount}\n`;
    confirmationMessage += `Delivery Date: ${delivery_date.toLocaleDateString()}\n`;
    confirmationMessage += `Time Slot: ${time_slot}\n\n`;
    confirmationMessage += `You will receive updates when your order is on the way!\n\n`;
    confirmationMessage += `Thank you for choosing Can Can! 💧`;

    await sendMessage(customerPhone, confirmationMessage);

  } catch (error) {
    console.error('Create final order error:', error);
    await sendMessage(customerPhone,
      "Sorry, there was an error completing your order. Please try again."
    );
  }
}

// Cancel order and clean up
async function cancelOrder(customerPhone: string, session: any) {
  try {
    // Clean up reservations
    await supabase
      .from('whatsapp_reservations')
      .update({ status: 'cancelled' })
      .eq('session_id', session.id);

    // Close session
    await supabase
      .from('whatsapp_sessions')
      .update({
        status: 'cancelled',
        updated_at: new Date().toISOString()
      })
      .eq('id', session.id);

    await sendMessage(customerPhone,
      "❌ Order cancelled. Your reserved inventory has been released.\n\n" +
      "If you'd like to place an order again, just send us a message like 'I need water cans'."
    );

  } catch (error) {
    console.error('Cancel order error:', error);
  }
}

// Legacy order request handler (kept for backward compatibility)
async function handleOrderRequest(
  customerPhone: string,
  messageId: string,
  orderDetection: any,
  timestamp: string
) {
  // This function is kept for backward compatibility but the new flow should be used
  console.log('Legacy order request handler called - using new enhanced flow instead');
  await initiateOrderFlow(customerPhone, messageId, orderDetection.originalText || '', timestamp);
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

// WhatsApp session management routes

// Get active sessions
router.get('/sessions', authenticateToken, async (req: any, res) => {
  try {
    const { data: sessions, error } = await supabase
      .from('whatsapp_sessions')
      .select(`
        *,
        customer:customers(name, phone),
        vendor:vendors(name, business_name)
      `)
      .eq('status', 'active')
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json({ sessions });
  } catch (error) {
    console.error('Get sessions error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get reservations
router.get('/reservations', authenticateToken, async (req: any, res) => {
  try {
    const { data: reservations, error } = await supabase
      .from('whatsapp_reservations')
      .select(`
        *,
        session:whatsapp_sessions(customer_phone),
        vendor:vendors(name),
        product:products(name, sku)
      `)
      .eq('status', 'reserved')
      .order('reserved_at', { ascending: false });

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    res.json({ reservations });
  } catch (error) {
    console.error('Get reservations error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Cancel session
router.post('/sessions/:sessionId/cancel', authenticateToken, async (req: any, res) => {
  try {
    const { sessionId } = req.params;

    // Get session
    const { data: session, error: sessionError } = await supabase
      .from('whatsapp_sessions')
      .select('*')
      .eq('id', sessionId)
      .single();

    if (sessionError || !session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    // Cancel the session
    await cancelOrder(session.customer_phone, session);

    res.json({ success: true, message: 'Session cancelled' });
  } catch (error) {
    console.error('Cancel session error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Cleanup expired reservations
router.post('/cleanup', authenticateToken, async (req: any, res) => {
  try {
    const { data, error } = await supabase.rpc('cleanup_expired_reservations');

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    // Also expire sessions older than 1 hour
    const oneHourAgo = new Date();
    oneHourAgo.setHours(oneHourAgo.getHours() - 1);

    const { data: expiredSessions } = await supabase
      .from('whatsapp_sessions')
      .update({ status: 'expired' })
      .eq('status', 'active')
      .lt('updated_at', oneHourAgo.toISOString())
      .select();

    res.json({
      success: true,
      message: 'Cleanup completed',
      expiredReservations: data,
      expiredSessions: expiredSessions?.length || 0
    });
  } catch (error) {
    console.error('Cleanup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
