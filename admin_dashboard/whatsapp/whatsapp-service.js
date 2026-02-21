/**
 * WHATSAPP BUSINESS INTEGRATION
 * Core message parsing, order creation, and customer communication
 * Works with Supabase database
 */

const { supabase } = require('../api/supabase-admin');
const crypto = require('crypto');
const WhatsAppMetaAPI = require('../services/whatsappMeta');

class WhatsAppService {
  constructor() {
    // Initialize REAL Meta API integration
    this.metaAPI = new WhatsAppMetaAPI();

    this.messagePatterns = {
      // Order patterns
      orderRequest: [
        /(?:need|want|require|get|order)\s+(\d+)\s*(?:water)?\s*(?:cans?|bottles?|jar(?:s)?)/i,
        /(?:send|deliver|bring)\s+(\d+)\s*(?:water)?\s*(?:cans?|bottles?|jar(?:s)?)/i,
        /(\d+)\s*(?:water)?\s*(?:cans?|bottles?|jar(?:s)?)/i
      ],

      // Pricing inquiries
      priceInquiry: [
        /(?:price|cost|rate|how much)/i,
        /(?:how much|cost|price)/i
      ],

      // Status inquiries
      statusInquiry: [
        /(?:status|where|when|track|delivery)/i,
        /(?:my order|status)/i
      ],

      // Cancellation
      cancellation: [
        /(?:cancel|stop|remove)/i,
        /(?:don'?t want|no longer need)/i
      ],

      // Address inquiry
      addressInquiry: [
        /(?:address|location|area)/i,
        /(?:where are you|location)/i
      ],

      // Business hours
      hoursInquiry: [
        /(?:hours|timing|open|close)/i,
        /(?:when are you open)/i
      ]
    };

    this.orderStates = {
      PENDING: 'pending',
      CONFIRMED: 'confirmed',
      PREPARING: 'preparing',
      OUT_FOR_DELIVERY: 'out_for_delivery',
      DELIVERED: 'delivered',
      CANCELLED: 'cancelled'
    };
  }

  /**
   * Parse WhatsApp message and determine intent
   */
  async parseMessage(message, customerPhone, vendorId = null) {
    try {
      const messageData = {
        originalMessage: message,
        customerPhone,
        vendorId,
        timestamp: new Date().toISOString(),
        intent: null,
        entities: {},
        response: null
      };

      // Parse message intent
      const intent = this.determineIntent(message);
      messageData.intent = intent;

      // Extract entities (quantities, addresses, etc.)
      const entities = this.extractEntities(message, intent);
      messageData.entities = entities;

      // Get or create customer
      const customer = await this.getOrCreateCustomer(customerPhone);
      if (!customer) {
        return this.createErrorResponse('Unable to verify customer account');
      }

      messageData.customer = customer;

      // Handle intent
      let response;
      switch (intent) {
        case 'order_request':
          response = await this.handleOrderRequest(messageData);
          break;
        case 'price_inquiry':
          response = await this.handlePriceInquiry(messageData);
          break;
        case 'status_inquiry':
          response = await this.handleStatusInquiry(messageData);
          break;
        case 'cancellation':
          response = await this.handleCancellation(messageData);
          break;
        case 'address_inquiry':
          response = await this.handleAddressInquiry(messageData);
          break;
        case 'hours_inquiry':
          response = await this.handleHoursInquiry(messageData);
          break;
        default:
          response = this.handleUnknownIntent(messageData);
      }

      // Log message
      await this.logWhatsAppMessage(messageData);

      return response;
    } catch (error) {
      console.error('Error parsing WhatsApp message:', error);
      return this.createErrorResponse('An error occurred while processing your request. Please try again.');
    }
  }

  /**
   * Determine intent from message
   */
  determineIntent(message) {
    const normalizedMessage = message.toLowerCase().trim();

    for (const [intent, patterns] of Object.entries(this.messagePatterns)) {
      for (const pattern of patterns) {
        if (pattern.test(normalizedMessage)) {
          return intent.toLowerCase();
        }
      }
    }

    return 'unknown';
  }

  /**
   * Extract entities from message
   */
  extractEntities(message, intent) {
    const entities = {};

    // Extract quantities
    if (intent === 'order_request') {
      const quantityMatches = message.match(/\d+/g);
      if (quantityMatches) {
        entities.quantity = parseInt(quantityMatches[0]);
      }
    }

    // Extract urgency indicators
    if (message.toLowerCase().includes('urgent') || message.toLowerCase().includes('asap')) {
      entities.urgency = 'high';
    }

    // Extract delivery time preferences
    if (message.toLowerCase().includes('morning')) {
      entities.preferredTime = 'morning';
    } else if (message.toLowerCase().includes('evening')) {
      entities.preferredTime = 'evening';
    } else if (message.toLowerCase().includes('tomorrow')) {
      entities.preferredDate = 'tomorrow';
    }

    return entities;
  }

  /**
   * Handle order request
   */
  async handleOrderRequest(messageData) {
    try {
      const { entities, customer } = messageData;
      const quantity = entities.quantity || 1;

      // Validate quantity
      if (quantity > 50) {
        return this.createResponse('For orders over 50 cans, please contact us directly at +919876543210');
      }

      // Find nearest available vendor
      const vendor = await this.findNearestAvailableVendor(customer);
      if (!vendor) {
        return this.createResponse('Sorry, we don\'t have any available vendors in your area at the moment. Please try again later.');
      }

      // Check vendor capacity
      if (!await this.checkVendorCapacity(vendor.id, quantity)) {
        return this.createResponse(`${vendor.business_name} is currently at full capacity. Would you like us to try another vendor or contact you back when available?`);
      }

      // Create order
      const orderData = {
        order_number: await this.generateOrderNumber(),
        customer_id: customer.id,
        vendor_id: vendor.id,
        order_items: [{
          product_id: 'default-water-can', // Will map to actual product
          quantity: quantity,
          unit_price: 40.00, // Default price, will get from vendor
          subtotal: quantity * 40.00
        }],
        delivery_address: customer.address ? this.formatAddress(customer) : this.getDefaultAddress(customer),
        delivery_date: new Date().toISOString().split('T')[0],
        delivery_time_slot: entities.preferredTime || 'ASAP',
        special_instructions: `WhatsApp order: ${messageData.originalMessage}`,
        status: this.orderStates.PENDING,
        subtotal: quantity * 40.00,
        delivery_fee: 10.00,
        tax_amount: (quantity * 40.00) * 0.05, // 5% tax
        total_amount: (quantity * 40.00) + 10.00 + ((quantity * 40.00) * 0.05),
        created_at: new Date().toISOString(),
        source: 'whatsapp'
      };

      const { data: order, error } = await supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

      if (error) {
        console.error('Error creating order:', error);
        return this.createErrorResponse('Sorry, we couldn\'t create your order. Please try again.');
      }

      // Send confirmation to customer
      const confirmationMessage = this.createOrderConfirmationMessage(order, vendor);

      // Send notification to vendor
      await this.notifyVendorOfNewOrder(order, vendor, customer);

      // Log order creation
      await supabase
        .from('notifications')
        .insert({
          recipient_type: 'vendor',
          recipient_id: vendor.id,
          title: 'New WhatsApp Order!',
          message: `New order #${order.order_number} from WhatsApp (${customer.name || customer.phone})`,
          type: 'new_order',
          data: { order_id: order.id, customer, order }
        });

      return {
        type: 'message',
        text: confirmationMessage,
        order: order
      };
    } catch (error) {
      console.error('Error handling order request:', error);
      return this.createErrorResponse('Sorry, we encountered an error while processing your order. Please try again or call us.');
    }
  }

  /**
   * Handle price inquiry
   */
  async handlePriceInquiry(messageData) {
    try {
      const vendor = await this.findNearestAvailableVendor(messageData.customer);
      if (!vendor) {
        return this.createResponse('Our pricing is:\n💧 20L Water Can: ₹40\n🚚 Delivery: ₹10\n💰 Total: ₹50\n\nNo vendors available in your area currently.');
      }

      // Get vendor pricing
      const { data: vendorProducts } = await supabase
        .from('vendor_products')
        .select('selling_price, products(name)')
        .eq('vendor_id', vendor.id)
        .eq('is_active', true)
        .limit(5);

      let pricingMessage = `${vendor.business_name} Pricing:\n\n`;

      if (vendorProducts && vendorProducts.length > 0) {
        vendorProducts.forEach(vp => {
          pricingMessage += `💧 ${vp.products.name}: ₹${vp.selling_price}\n`;
        });
      } else {
        pricingMessage += `💧 20L Water Can: ₹40\n`;
      }

      pricingMessage += `\n🚚 Delivery: ₹10\n💰 Total (with tax): ₹50\n\nWould you like to place an order?`;

      return this.createResponse(pricingMessage);
    } catch (error) {
      console.error('Error handling price inquiry:', error);
      return this.createResponse('Standard pricing: ₹40 per 20L can + ₹10 delivery. Total: ₹50');
    }
  }

  /**
   * Handle status inquiry
   */
  async handleStatusInquiry(messageData) {
    try {
      const { customer } = messageData;

      // Get customer's recent orders
      const { data: orders } = await supabase
        .from('orders')
        .select('order_number, status, vendor_id, created_at, delivery_date, vendors(business_name)')
        .eq('customer_id', customer.id)
        .order('created_at', { ascending: false })
        .limit(5);

      if (!orders || orders.length === 0) {
        return this.createResponse('You don\'t have any recent orders. Would you like to place one? Just message how many water cans you need!');
      }

      let statusMessage = 'Your recent orders:\n\n';

      orders.forEach((order, index) => {
        const statusIcon = this.getStatusEmoji(order.status);
        const timeAgo = this.getTimeAgo(order.created_at);
        statusMessage += `${index + 1}. Order #${order.order_number}\n   ${statusIcon} ${this.getStatusText(order.status)}\n   ${order.vendors.business_name}\n   Ordered: ${timeAgo}\n\n`;
      });

      statusMessage += 'Reply with "cancel [order number]" to cancel any pending order.';

      return this.createResponse(statusMessage);
    } catch (error) {
      console.error('Error handling status inquiry:', error);
      return this.createResponse('Sorry, I couldn\'t fetch your order status. Please try again later.');
    }
  }

  /**
   * Handle cancellation
   */
  async handleCancellation(messageData) {
    try {
      const { customer } = messageData;

      // Extract order number if mentioned
      const orderNumberMatch = messageData.originalMessage.match(/#?(\d+)/);

      if (orderNumberMatch) {
        const orderNumber = orderNumberMatch[1];
        return await this.cancelSpecificOrder(orderNumber, customer);
      }

      // Get customer's pending orders
      const { data: orders } = await supabase
        .from('orders')
        .select('id, order_number, status')
        .eq('customer_id', customer.id)
        .in('status', [this.orderStates.PENDING, this.orderStates.CONFIRMED])
        .limit(5);

      if (!orders || orders.length === 0) {
        return this.createResponse('You don\'t have any pending orders to cancel. Good to know though!');
      }

      if (orders.length === 1) {
        return await this.cancelSpecificOrder(orders[0].order_number, customer);
      }

      // Multiple orders - ask which one
      let cancellationMessage = 'You have multiple pending orders. Which one would you like to cancel?\n\n';
      orders.forEach((order, index) => {
        cancellationMessage += `${index + 1}. Order #${order.order_number}\n`;
      });
      cancellationMessage += '\n\nReply with the order number to cancel.';

      return this.createResponse(cancellationMessage);
    } catch (error) {
      console.error('Error handling cancellation:', error);
      return this.createResponse('Sorry, I couldn\'t process your cancellation. Please contact customer support.');
    }
  }

  /**
   * Cancel specific order
   */
  async cancelSpecificOrder(orderNumber, customer) {
    try {
      const { data: order, error } = await supabase
        .from('orders')
        .update({
          status: this.orderStates.CANCELLED,
          cancelled_at: new Date().toISOString(),
          cancellation_reason: 'Customer cancelled via WhatsApp',
          updated_at: new Date().toISOString()
        })
        .eq('customer_id', customer.id)
        .eq('order_number', orderNumber)
        .select()
        .single();

      if (error) {
        return this.createResponse('Sorry, I couldn\'t find or cancel that order. Please check the order number.');
      }

      // Notify vendor
      await supabase
        .from('notifications')
        .insert({
          recipient_type: 'vendor',
          recipient_id: order.vendor_id,
          title: 'Order Cancelled',
          message: `Order #${orderNumber} was cancelled by customer via WhatsApp`,
          type: 'order_cancelled',
          data: { order_id: order.id, customer }
        });

      return this.createResponse(`Order #${orderNumber} has been cancelled. You won't be charged anything. Is there anything else I can help with?`);
    } catch (error) {
      console.error('Error cancelling order:', error);
      return this.createResponse('Sorry, there was an error cancelling your order. Please contact customer support immediately.');
    }
  }

  /**
   * Handle address inquiry
   */
  async handleAddressInquiry(messageData) {
    try {
      const vendor = await this.findNearestAvailableVendor(messageData.customer);
      if (!vendor) {
        return this.createResponse('We currently don\'t have vendors available in your area. We\'re expanding our service soon!');
      }

      return this.createResponse(`Your order will be delivered by:\n\n${vendor.business_name}\n📍 ${this.formatVendorAddress(vendor)}\n\nWe\'ll deliver as soon as possible!`);
    } catch (error) {
      console.error('Error handling address inquiry:', error);
      return this.createResponse('Our vendors cover major areas in the city. Please share your location for specific service availability.');
    }
  }

  /**
   * Handle hours inquiry
   */
  async handleHoursInquiry(messageData) {
    return this.createResponse('We operate daily from 9 AM to 9 PM. WhatsApp ordering is available 24/7! 🕰️\n\nPlace your order anytime and we\'ll deliver during business hours.');
  }

  /**
   * Handle unknown intent
   */
  handleUnknownIntent(messageData) {
    return this.createResponse(
      'I can help you with:\n\n' +
      '📦 Order water cans (e.g., "I need 2 water cans")\n' +
      '💰 Check pricing ("What\'s the price?")\n' +
      '📊 Track orders ("What\'s my order status?")\n' +
      '📍 Check delivery area ("Where do you deliver?")\n' +
      '🕐️ Business hours ("What are your hours?")\n\n' +
      'How can I help you today?'
    );
  }

  /**
   * Get or create customer from phone number
   */
  async getOrCreateCustomer(phoneNumber) {
    try {
      // First try to get existing customer
      const { data: customer, error } = await supabase
        .from('customers')
        .select('*')
        .eq('phone', phoneNumber)
        .single();

      if (customer) {
        return customer;
      }

      // Create new customer
      const { data: newCustomer, error: insertError } = await supabase
        .from('customers')
        .insert({
          phone: phoneNumber,
          name: `Customer ${phoneNumber.slice(-4)}`,
          verification_status: 'verified', // WhatsApp users are considered verified
          is_active: true,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .select()
        .single();

      if (insertError) {
        console.error('Error creating customer:', insertError);
        return null;
      }

      // Send welcome notification
      await supabase
        .from('notifications')
        .insert({
          recipient_type: 'customer',
          recipient_id: newCustomer.id,
          title: 'Welcome to Can Can!',
          message: `Hi ${newCustomer.name}! Thanks for reaching out. We\'re excited to serve you.`,
          type: 'welcome',
          data: { customer: newCustomer }
        });

      return newCustomer;
    } catch (error) {
      console.error('Error getting or creating customer:', error);
      return null;
    }
  }

  /**
   * Find nearest available vendor
   */
  async findNearestAvailableVendor(customer) {
    try {
      if (!customer.latitude || !customer.longitude) {
        return this.findDefaultVendor();
      }

      // Use Supabase geospatial function
      const { data, error } = await supabase.rpc('find_nearest_vendors', {
        p_latitude: customer.latitude,
        p_longitude: customer.longitude,
        p_radius_km: 10,
        p_limit: 1,
      });

      if (error || !data || data.length === 0) {
        return this.findDefaultVendor();
      }

      return data[0];
    } catch (error) {
      console.error('Error finding vendor:', error);
      return this.findDefaultVendor();
    }
  }

  /**
   * Find default vendor (fallback)
   */
  async findDefaultVendor() {
    try {
      const { data, error } = await supabase
        .from('vendors')
        .select('*')
        .eq('is_active', true)
        .eq('is_verified', true)
        .eq('is_on_vacation', false)
        .limit(1)
        .order('rating', { ascending: false });

      return error || data.length === 0 ? null : data[0];
    } catch (error) {
      console.error('Error finding default vendor:', error);
      return null;
    }
  }

  /**
   * Check if vendor can handle the order
   */
  async checkVendorCapacity(vendorId, quantity) {
    try {
      // For simplicity, assume all vendors can handle up to 50 cans
      return quantity <= 50;
    } catch (error) {
      console.error('Error checking vendor capacity:', error);
      return false;
    }
  }

  /**
   * Generate unique order number
   */
  async generateOrderNumber() {
    try {
      const timestamp = Date.now();
      const random = Math.floor(Math.random() * 1000);
      return `WHA${timestamp}${random}`;
    } catch (error) {
      console.error('Error generating order number:', error);
      return `WHA${Date.now()}`;
    }
  }

  /**
   * Create order confirmation message
   */
  createOrderConfirmationMessage(order, vendor) {
    return `✅ Order Confirmed!\n\n` +
           `Order #${order.order_number}\n` +
           `Quantity: ${order.order_items[0]?.quantity || 1} water cans\n` +
           `Total: ₹${order.total_amount}\n` +
           `Vendor: ${vendor.business_name}\n` +
           `Estimated Delivery: ASAP\n\n` +
           `You\'ll receive real-time updates on your order status. Thank you for choosing Can Can! 💧`;
  }

  /**
   * Notify vendor of new order
   */
  async notifyVendorOfNewOrder(order, vendor, customer) {
    try {
      // Send notification via database (will be sent through Supabase Realtime)
      await supabase
        .from('notifications')
        .insert({
          recipient_type: 'vendor',
          recipient_id: vendor.id,
          title: '🔔 NEW ORDER RECEIVED!',
          message: `WhatsApp Order: #${order.order_number}\nCustomer: ${customer.name || customer.phone}\nQuantity: ${order.order_items[0]?.quantity || 1} cans\nTotal: ₹${order.total_amount}`,
          type: 'new_order',
          data: {
            order_id: order.id,
            customer,
            urgent: true
          }
        });

      // In production, also send WhatsApp to vendor if they have WhatsApp enabled
      // This would require WhatsApp Business API for vendors
    } catch (error) {
      console.error('Error notifying vendor:', error);
    }
  }

  /**
   * Log WhatsApp message
   */
  async logWhatsAppMessage(messageData) {
    try {
      await supabase
        .from('whatsapp_messages')
        .insert({
          customer_phone: messageData.customerPhone,
          vendor_id: messageData.vendorId,
          message: messageData.originalMessage,
          intent: messageData.intent,
          entities: messageData.entities,
          response: messageData.response,
          direction: 'incoming',
          processed_at: new Date().toISOString()
        });
    } catch (error) {
      console.error('Error logging WhatsApp message:', error);
    }
  }

  /**
   * Format address for display
   */
  formatAddress(customer) {
    if (!customer.address) return 'Address not provided';

    let formattedAddress = customer.address;

    if (customer.building_name) {
      formattedAddress = `${customer.building_name}, ${formattedAddress}`;
    }

    if (customer.flat_number) {
      formattedAddress = `Flat ${customer.flat_number}, ${formattedAddress}`;
    }

    if (customer.floor) {
      formattedAddress = `Floor ${customer.floor}, ${formattedAddress}`;
    }

    return formattedAddress;
  }

  /**
   * Format vendor address
   */
  formatVendorAddress(vendor) {
    let address = vendor.address;

    if (vendor.building_name) {
      address += `, ${vendor.building_name}`;
    }

    if (vendor.flat_number) {
      address = `Flat ${vendor.flat_number}, ${address}`;
    }

    if (vendor.city) {
      address += `, ${vendor.city}`;
    }

    if (vendor.pincode) {
      address += ` - ${vendor.pincode}`;
    }

    return address;
  }

  /**
   * Get default address for customer
   */
  getDefaultAddress(customer) {
    return customer.address || 'Address to be updated in profile';
  }

  /**
   * Create response message
   */
  createResponse(text) {
    return {
      type: 'message',
      text: text
    };
  }

  /**
   * Create error response
   */
  createErrorResponse(message) {
    return {
      type: 'error',
      text: `❌ ${message}`
    };
  }

  /**
   * Get status emoji
   */
  getStatusEmoji(status) {
    const statusEmojis = {
      'pending': '⏳️',
      'confirmed': '✅',
      'preparing': '👨',
      'out_for_delivery': '🚚',
      'delivered': '✅',
      'cancelled': '❌'
    };
    return statusEmojis[status] || '❓';
  }

  /**
   * Get status text
   */
  getStatusText(status) {
    const statusTexts = {
      'pending': 'Pending Confirmation',
      'confirmed': 'Confirmed',
      'preparing': 'Preparing for Delivery',
      'out_for_delivery': 'Out for Delivery',
      'delivered': 'Delivered Successfully',
      'cancelled': 'Cancelled'
    };
    return statusTexts[status] || 'Unknown';
  }

  /**
   * Get time ago string
   */
  getTimeAgo(dateString) {
    const now = new Date();
    const date = new Date(dateString);
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) {
      return 'Just now';
    } else if (diffMins < 60) {
      return `${diffMins} minutes ago`;
    } else if (diffMins < 1440) { // 24 hours
      const hours = Math.floor(diffMins / 60);
      return `${hours} hours ago`;
    } else {
      const days = Math.floor(diffMins / 1440);
      return `${days} days ago`;
    }
  }

  /**
   * Process webhook from WhatsApp Business API
   */
  async processWebhook(webhookData) {
    try {
      const { object: changes } = webhookData.entry?.[0] || {};
      const { value: message } = changes[0]?.messages?.[0] || {};

      if (!message) {
        return { success: false, error: 'No message found in webhook' };
      }

      // Extract message content
      let messageText = '';
      if (message.text) {
        messageText = message.text.body;
      } else if (message.image) {
        messageText = '[Image]'; // Handle image messages
      }

      if (!messageText) {
        return { success: false, error: 'Empty message content' };
      }

      // Extract customer phone
      const customerPhone = message.from;
      if (!customerPhone) {
        return { success: false, error: 'No customer phone found' };
      }

      // Process the message
      const response = await this.parseMessage(
        messageText,
        customerPhone
      );

      // Send response back to WhatsApp (this would use WhatsApp Business API)
      if (response) {
        await this.sendWhatsAppResponse(customerPhone, response);
      }

      return {
        success: true,
        processed: true,
        response
      };
    } catch (error) {
      console.error('Error processing webhook:', error);
      return {
        success: false,
        error: 'Webhook processing failed',
        details: error.message
      };
    }
  }

  /**
   * Send response back to WhatsApp using REAL Meta API
   */
  async sendWhatsAppResponse(customerPhone, response) {
    try {
      console.log('Sending WhatsApp Response via Meta API:', {
        customerPhone,
        response,
        timestamp: new Date().toISOString()
      });

      // Use REAL Meta API to send message
      const messageText = this.formatResponseMessage(response);
      const result = await this.metaAPI.sendMessage(customerPhone, messageText, 'text');

      if (result.success) {
        // Log successful message
        await supabase.from('whatsapp_logs').insert({
          to_phone: customerPhone,
          message_type: 'response',
          message_id: result.messageId,
          status: 'sent',
          response_data: response,
          created_at: new Date().toISOString()
        });

        console.log('WhatsApp response sent successfully:', result.messageId);
        return true;
      } else {
        console.error('Failed to send WhatsApp response:', result.error);
        return false;
      }

    } catch (error) {
      console.error('Error sending WhatsApp response:', error);
      return false;
    }
  }

  /**
   * Format response message for WhatsApp
   */
  formatResponseMessage(response) {
    let message = '';

    if (response.intent === 'order_request') {
      message = `✅ *Order Received!*\n\nWe've received your order for ${response.quantity} water cans.\n\n📍 *Delivery Address*: ${response.address}\n💰 *Estimated Cost*: ₹${response.cost}\n⏰ *Estimated Delivery*: ${response.deliveryTime}\n\nWe'll confirm your order shortly. Thank you! 💧`;
    } else if (response.intent === 'price_inquiry') {
      message = `💰 *Water Can Pricing*\n\n🔹 *20L Water Can*: ₹${response.price20L || '50-70'}\n🔹 *10L Water Jar*: ₹${response.price10L || '30-50'}\n\n🚚 *Delivery Fee*: ₹${response.deliveryFee || '10-20'}\n📍 *Service Area*: ${response.serviceArea}\n\nFor orders, simply text: "Order [quantity] [your address]"\nExample: "Order 2 20L cans to 123 Main Street, City"`;
    } else if (response.intent === 'status_inquiry') {
      message = `📦 *Order Status*\n\n🎯 *Order ID*: ${response.orderId}\n📊 *Current Status*: ${this.getStatusText(response.status)}\n📍 *Delivery Address*: ${response.address}\n\n${response.estimatedTime ? `⏰ *Estimated Arrival*: ${response.estimatedTime}` : ''}\n\nFor real-time updates, please call: ${response.contactPhone}`;
    } else if (response.intent === 'welcome') {
      message = `👋 *Welcome to Can Can Water Delivery!*\n\n💧 *Quick Order*: "Order [quantity] [address]"\nExample: "Order 2 20L cans to 123 Main Street"\n\n🏪 *Our Services*:\n• 20L Water Cans: ₹50-70\n• 10L Water Jars: ₹30-50\n• Fast Delivery: 30-60 minutes\n• Available 24/7\n\n📞 *Need Help?*: Call ${response.contactPhone}\n\nThank you for choosing Can Can! 🚀`;
    } else {
      message = `Thank you for your message! 🙏\n\nFor water can delivery orders, please text:\n"Order [quantity] [address]"\n\nOr call us at: ${response.contactPhone || '+919876543210'}\n\nWe'll be happy to help! 💧`;
    }

    return message;
  }
}

module.exports = WhatsAppService;