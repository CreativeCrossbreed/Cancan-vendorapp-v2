# WhatsApp Enhanced Ordering System Setup Guide

## Overview

This guide walks you through setting up the enhanced WhatsApp ordering system for the Can Can water delivery vendor app. The new system implements a sophisticated conversational flow that allows customers to:

1. **Select from multiple vendors** with confirmation
2. **View available inventory** with SKUs, quantities, and prices
3. **Reserve inventory** temporarily (15-minute window)
4. **Select multiple items** with flexible ordering
5. **Confirm order details** before final placement

## System Architecture

### Enhanced WhatsApp Flow
```
Customer Message → Webhook → Session Management → Interactive Order Flow → Order Creation
```

#### Flow States:
1. **vendor_confirmation**: Customer selects vendor from available options
2. **inventory_display**: Show vendor inventory with prices and stock
3. **additional_items**: Handle adding more items to cart
4. **order_confirmation**: Final review and confirmation

## Database Schema Changes

### New Tables

#### `whatsapp_sessions`
- Tracks customer conversation sessions
- Stores session state and data
- Links customers to selected vendors

#### `whatsapp_reservations`
- Temporary inventory reservations
- 15-minute expiration window
- Prevents overselling during order flow

## Setup Instructions

### 1. Database Migration

Run the enhanced schema script:

```bash
# Connect to your Supabase database
supabase db push

# Or run the SQL directly
psql -h YOUR_DB_HOST -U YOUR_USER -d YOUR_DB -f backend/whatsapp_enhanced_schema.sql
```

### 2. Environment Variables

Update your `.env` file:

```bash
# WhatsApp Business API Configuration
WHATSAPP_API_TOKEN=your_whatsapp_api_token
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id
WHATSAPP_WEBHOOK_SECRET=your_webhook_secret
WHATSAPP_BUSINESS_ACCOUNT_ID=your_business_account_id

# Webhook URL (replace with your deployed URL)
WEBHOOK_URL=https://your-domain.com/api/whatsapp/webhook
```

### 3. WhatsApp Business API Setup

1. **Create WhatsApp Business Account**
   - Go to [Meta for Developers](https://developers.facebook.com/)
   - Create a new app with WhatsApp product

2. **Configure Webhook**
   - Set webhook URL: `https://your-domain.com/api/whatsapp/webhook`
   - Verify webhook with your secret
   - Subscribe to `messages` field

3. **Get Phone Number ID**
   - Add or select a phone number in WhatsApp Business settings
   - Copy the Phone Number ID for environment variables

### 4. Backend Configuration

The enhanced WhatsApp system is already implemented in:
- `backend/src/routes/whatsapp.ts` - Main webhook handlers
- `backend/whatsapp_enhanced_schema.sql` - Database schema

### 5. Webhook Configuration

Update your deployed server's webhook configuration:

```javascript
// In your server.js or main app file
app.use('/api/whatsapp', whatsappRoutes);
```

## Customer Interaction Flow

### Example Conversation

**Customer:** "Hi, I need to order water cans"

**System:**
```
🤖 Can Can Water Delivery

We found available vendors for your order:

1. Aqua Fresh Water Services (Aqua Fresh)
2. Pure Water Delivered (Pure Water)
3. City Water Supply (City Water)

Please reply with the vendor number (1-3) to confirm:
```

**Customer:** "1"

**System:**
```
📦 Aqua Fresh Water Services - Available Inventory

1. Water Can (WC001)
   Available: 50 units
   Price: ₹40 each

2. 20 Liter Water Can (WC020)
   Available: 25 units
   Price: ₹60 each

3. 5 Liter Water Can (WC005)
   Available: 30 units
   Price: ₹30 each

Please reply with the item number and quantity:
Example: "2 3" for 3 units of item #2

Type "done" when finished adding items.
```

**Customer:** "1 2"

**System:**
```
✅ Added 2 x Water Can to your order

Would you like to add more items?

1. Yes, add more items
2. No, proceed to checkout
```

**Customer:** "2"

**System:**
```
📋 Order Summary

Vendor: Aqua Fresh Water Services

Items:
1. Water Can x 2 = ₹80

Total Amount: ₹80

📍 Delivery Address:
[Please confirm your delivery address]

Please reply:
"confirm" to place this order
"cancel" to cancel this order
"change" to modify your address
```

## Admin Features

### Session Management

New admin endpoints for managing WhatsApp sessions:

```bash
# Get active sessions
GET /api/whatsapp/sessions

# Get current reservations
GET /api/whatsapp/reservations

# Cancel specific session
POST /api/whatsapp/sessions/:sessionId/cancel

# Cleanup expired reservations
POST /api/whatsapp/cleanup
```

### Monitoring

- **Real-time session tracking** in admin dashboard
- **Inventory reservation monitoring**
- **Session timeout management** (1-hour auto-expire)
- **Expired reservation cleanup**

## Error Handling

### Common Scenarios

1. **No available vendors**: Fallback message asking to try later
2. **Insufficient inventory**: Show available alternatives
3. **Session timeout**: Clean up and restart flow
4. **Invalid input**: Clear instructions and examples
5. **Order creation failure**: Error message with retry option

### Reservation System

- **15-minute reservation window** per session
- **Automatic cleanup** of expired reservations
- **Concurrent session protection** prevents overselling
- **Graceful handling** of reservation conflicts

## Testing

### Development Setup

```bash
# Start the backend server
cd backend
npm start

# Use ngrok for local webhook testing
ngrok http 3000

# Update webhook URL in WhatsApp Business settings
# Use the ngrok URL: https://your-ngrok-url.ngrok.io/api/whatsapp/webhook
```

### Test Messages

1. **Order initiation**: "I need water cans", "Order 2 water cans"
2. **Vendor selection**: "1", "2", "3" (based on available vendors)
3. **Item selection**: "1 2", "3 1" (item_number quantity)
4. **Session control**: "done", "confirm", "cancel", "change"

## Production Considerations

### Scalability

- **Session pooling** for high-volume periods
- **Queue management** for concurrent orders
- **Load balancing** across multiple webhook endpoints

### Security

- **Webhook verification** using HMAC signatures
- **Rate limiting** to prevent abuse
- **Input sanitization** for all user inputs
- **Session timeout** protection

### Monitoring

- **Session analytics** and conversion tracking
- **Inventory reservation** metrics
- **Error rate monitoring** and alerting
- **Performance metrics** for response times

## Troubleshooting

### Common Issues

1. **Webhook not receiving messages**
   - Check webhook URL is accessible
   - Verify webhook subscription
   - Check SSL certificate validity

2. **Database connection errors**
   - Verify Supabase credentials
   - Check database connectivity
   - Review schema migrations

3. **Session state corruption**
   - Check session_data JSON structure
   - Verify database constraints
   - Clear expired sessions manually

### Debug Mode

Enable debug logging:

```bash
# Set environment variable
DEBUG=whatsapp

# Check logs for detailed session flow
tail -f logs/app.log
```

## API Documentation

### Webhook Events

The system handles these WhatsApp events:
- `text` messages
- `interactive` button responses (future enhancement)
- `location` messages (future enhancement)

### Response Format

All WhatsApp responses follow this structure:
```javascript
{
  "messaging_product": "whatsapp",
  "to": "customer_phone_number",
  "type": "text",
  "text": {
    "body": "formatted_message_text"
  }
}
```

## Future Enhancements

### Planned Features

1. **Interactive buttons** for better UX
2. **Location sharing** for delivery addresses
3. **Payment integration** via WhatsApp Pay
4. **Order tracking** with real-time updates
5. **Multi-language support**
6. **Voice message support**
7. **Image menu** for product selection

### Integration Opportunities

- **Customer CRM** integration
- **Analytics dashboard** for WhatsApp orders
- **Inventory alerts** for low stock
- **Automated follow-ups** for reviews
- **Loyalty program** integration

---

## Support

For technical support:
1. Check the troubleshooting section
2. Review server logs for detailed errors
3. Verify database schema and connections
4. Test webhook connectivity with ngrok

The enhanced WhatsApp system provides a complete conversational commerce solution for water delivery vendors, improving customer experience and operational efficiency.