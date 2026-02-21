# 🚀 WhatsApp Business API Setup Guide
## Complete Meta for Developers Integration

---

## 📋 **PREREQUISITES**

### Required Items:
1. **Meta Business Account** (Free)
2. **Facebook Business Page** (Free)
3. **WhatsApp Business App** (Free to create)
4. **Phone Number** (Must be able to receive SMS/calls)
5. **Credit Card** (For verification, can use $1 test transactions)
6. **Server** (For webhook endpoint - HTTPS required)

---

## 🎯 **STEP 1: META BUSINESS SETUP**

### 1.1 Create Meta Business Account
1. Go to [business.facebook.com](https://business.facebook.com)
2. Click "Create Account"
3. Enter your business details:
   - Business name: "Can Can Water Delivery"
   - Business category: "Delivery Service"
   - Business email: your-email@domain.com
   - Business phone: +91XXXXXXXXXX
4. Verify your email address
5. Verify your phone number (you'll receive a code via SMS)

### 1.2 Create Facebook Business Page
1. From Meta Business Suite, click "Create Page"
2. Page name: "Can Can Water Delivery"
3. Category: "Delivery Service"
4. Add profile picture (your company logo)
5. Add cover photo (water delivery themed)
6. Add business details:
   - Address: Your business address
   - Phone: Your business phone
   - Website: Your website URL
   - Description: Water can delivery service in your area

---

## 🎯 **STEP 2: WHATSAPP BUSINESS SETUP**

### 2.1 Get WhatsApp Business API Access
1. Go to [developers.facebook.com](https://developers.facebook.com)
2. Click "My Apps" → "Create App"
3. Choose "Business" app type
4. App name: "Can Can WhatsApp Integration"
5. App contact email: your-email@domain.com
6. Select "Business" category
7. Click "Create App"

### 2.2 Add WhatsApp Product
1. In your app dashboard, click "Add Product"
2. Select "WhatsApp"
3. Choose "Business" (not "Personal")
4. Select your Facebook Business Page
5. Enter your business phone number:
   - Must be a real phone number that can receive calls/SMS
   - Format: +91XXXXXXXXXX (with country code)
6. Click "Next"

### 2.3 Phone Number Verification
**Option A: SMS Verification (Recommended)**
1. Click "Send SMS" to receive a 6-digit code
2. Enter the code when received
3. Your phone number is now verified

**Option B: Call Verification**
1. Click "Call me" to receive an automated call
2. Listen for the 6-digit code
3. Enter the code
4. Your phone number is now verified

---

## 🎯 **STEP 3: WHATSAPP BUSINESS APP CONFIGURATION**

### 3.1 Configure Webhook URL
1. In your WhatsApp dashboard, click "Configuration"
2. Click "Edit" next to "Webhook URL"
3. Enter your webhook URL: `https://yourdomain.com/api/webhooks/whatsapp`
4. Enter webhook verify token: Create a secure token, e.g., `cancan_webhook_2024_secret_key`
5. Click "Verify and Save"

### 3.2 Webhook Server Setup
Create a secure webhook endpoint:

```javascript
// In your server.js
app.post('/api/webhooks/whatsapp', (req, res) => {
  // Verify webhook signature
  const signature = req.headers['x-hub-signature-256'];
  const expectedSignature = 'sha256=' + crypto
    .createHmac('sha256', process.env.WHATSAPP_WEBHOOK_SECRET)
    .update(JSON.stringify(req.body))
    .digest('hex');

  if (signature !== expectedSignature) {
    return res.status(401).json({ error: 'Invalid webhook signature' });
  }

  // Process WhatsApp webhook
  console.log('WhatsApp webhook received:', req.body);
  res.status(200).json({ status: 'received' });
});
```

### 3.3 Environment Variables
Add these to your `.env` file:

```env
# WhatsApp Business API Configuration
WHATSAPP_API_KEY=your-api-key-from-meta
WHATSAPP_PHONE_NUMBER_ID=your-phone-number-id
WHATSAPP_WEBHOOK_SECRET=cancan_webhook_2024_secret_key
WHATSAPP_WEBHOOK_URL=https://yourdomain.com/api/webhooks/whatsapp
WHATSAPP_VERSION=v18.0
WHATSAPP_PHONE_NUMBER=+91XXXXXXXXXX
```

---

## 🎯 **STEP 4: MESSAGE TEMPLATES**

### 4.1 Create Message Templates
1. In WhatsApp dashboard → "Message Templates"
2. Click "Create Template"
3. Choose template type: "Marketing" or "Utility"

### 4.2 Required Templates for Can Can:

#### **Order Confirmation Template**
```
Template Name: order_confirmation_v2
Category: Utility
Language: English

Body:
Hello {{1}}!

Your water can order ({{2}}) has been confirmed and assigned to our delivery partner.

Order Details:
• Order ID: {{3}}
• Items: {{4}}
• Total: ₹{{5}}
• Estimated delivery: {{6}}

You'll receive real-time updates on your delivery. Reply HELP for assistance.

Thank you for choosing Can Can Water Delivery!
```

#### **Delivery Update Template**
```
Template Name: delivery_update_v2
Category: Utility
Language: English

Body:
Hi {{1}}!

Your order {{2}} is now {{3}}.

📍 Current status: {{4}}
📍 Delivery partner: {{5}}
📱 Contact: {{6}}

Estimated arrival: {{7}}

Track your delivery in real-time!
- Reply "STATUS" for updates
- Reply "CANCEL" to cancel (if allowed)

Thank you for your patience!
```

#### **Payment Reminder Template**
```
Template Name: payment_reminder_v2
Category: Utility
Language: English

Body:
Hi {{1}}!

Friendly reminder: Your water can order {{2}} payment is due.

Order Details:
• Amount due: ₹{{3}}
• Order ID: {{4}}
• Due date: {{5}}

Payment Options:
1. Pay on delivery
2. UPI: your-upi-id@bank
3. Net Banking: [link]

Please complete payment before delivery.

Questions? Call us at {{6}}.
```

#### **Welcome Message Template**
```
Template Name: welcome_message_v2
Category: Marketing
Language: English

Body:
Welcome to Can Can Water Delivery! 🚰💧

Get fresh water cans delivered to your doorstep in minutes!

🌟 Our Services:
• 20L Water Cans: ₹50-₹80
• 10L Water Jars: ₹30-₅0
• Fast Delivery: 30-60 minutes
• Available 24/7

📞 Order via WhatsApp:
"Order [quantity] [address]"

Example: "Order 2 20L cans to 123 Main Street"

Need help? Call: {{1}}
Download our app: [app-link]

Stay hydrated with Can Can! 💧
```

### 4.3 Template Approval Process
1. Submit templates for review (takes 1-2 business days)
2. WhatsApp will review for compliance
3. You'll receive email notification when approved
4. Templates must not contain promotional content in "Utility" category

---

## 🎯 **STEP 5: TESTING CONFIGURATION**

### 5.1 Send Test Messages
1. In WhatsApp dashboard → "Message Templates"
2. Click "Send Test" next to approved template
3. Enter your phone number
4. Fill template variables
5. Click "Send"

### 5.2 Webhook Testing
1. Use tools like ngrok for local testing:
   ```bash
   ngrok http 3001
   ```
2. Use ngrok URL for webhook during development
3. Test webhook endpoint with Meta's Webhook Tool

---

## 🎯 **STEP 6: PRODUCTION SETUP**

### 6.1 HTTPS Certificate (Required)
```bash
# Using Let's Encrypt
sudo certbot --nginx -d yourdomain.com
```

### 6.2 Server Security
```javascript
// Add these security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "connect.facebook.net"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"]
    }
  }
}));
```

### 6.3 Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');

const whatsappLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute
  message: 'Too many WhatsApp requests',
  standardHeaders: true,
  legacyHeaders: false,
});
```

---

## 🎯 **STEP 7: COST MANAGEMENT**

### 7.1 WhatsApp Business API Pricing
- **Free Tier**: 1,000 conversations/month
- **Business Pricing**: ₹0.30-₹0.50 per conversation
- **Template Messages**: Billed per template send
- **Session Messages**: Free for 24-hour window

### 7.2 Cost Optimization Tips
1. Use template messages only for necessary communications
2. Combine multiple updates in single messages
3. Use customer service window for conversations
4. Monitor usage in Meta Business Suite
5. Set usage alerts and limits

---

## 🚨 **COMMON ISSUES & SOLUTIONS**

### Issue 1: Webhook Not Working
- **Problem**: Webhook URL not reachable
- **Solution**:
  - Ensure HTTPS (required for production)
  - Check firewall settings
  - Verify webhook URL is correct
  - Test with ngrok for local development

### Issue 2: Template Rejected
- **Problem**: Template not approved
- **Solution**:
  - Remove promotional content from utility templates
  - Use proper formatting and variables
  - Avoid personalization beyond allowed limits
  - Follow WhatsApp Commerce Policy

### Issue 3: Phone Number Blocked
- **Problem**: Phone number flagged
- **Solution**:
  - Reduce message frequency
  - Avoid spam-like behavior
  - Focus on quality over quantity
  - Use opt-in properly

### Issue 4: High Costs
- **Problem**: Unexpected high charges
- **Solution**:
  - Monitor conversation types
  - Use free conversation window wisely
  - Optimize message templates
  - Set up cost alerts

---

## 📋 **CHECKLIST FOR LAUNCH**

### Pre-Launch Checklist:
- [ ] Meta Business Account verified
- [ ] Facebook Business Page complete
- [ ] WhatsApp Business App approved
- [ ] Phone number verified and ported
- [ ] Webhook endpoint HTTPS secured
- [ ] All message templates approved
- [ ] Test messages sent successfully
- [ ] Webhook integration tested
- [ ] Rate limiting configured
- [ ] Error handling implemented
- [ ] Monitoring and logging setup
- [ ] Cost controls configured
- [ ] Backup webhook URL configured

### Post-Launch Monitoring:
- [ ] Message delivery rates
- [ ] Webhook response times
- [ ] Template approval status
- [ ] Phone number health
- [ ] Cost tracking
- [ ] Customer feedback
- [ ] Error rates and patterns

---

## 🛠️ **INTEGRATION WITH CAN CAN SYSTEM**

### Update your WhatsApp service to use Meta API:

```javascript
// In whatsapp-service.js
class WhatsAppService {
  constructor() {
    this.apiVersion = process.env.WHATSAPP_VERSION || 'v18.0';
    this.phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
    this.accessToken = process.env.WHATSAPP_API_KEY;
  }

  async sendMessage(to, templateName, components) {
    const url = `https://graph.facebook.com/${this.apiVersion}/${this.phoneNumberId}/messages`;

    const payload = {
      messaging_product: 'whatsapp',
      to: to.replace('+', ''), // Remove + for API
      type: 'template',
      template: {
        name: templateName,
        language: { code: 'en' },
        components: components
      }
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    return response.json();
  }
}
```

---

## 🎯 **SUPPORT & CONTACT**

### Meta Business Support:
- [Meta Business Help Center](https://www.facebook.com/business/help)
- [WhatsApp Business API Documentation](https://developers.facebook.com/docs/whatsapp/)
- [Meta Developers Support](https://developers.facebook.com/support/)

### Common Support Articles:
- [WhatsApp Business API Pricing](https://www.facebook.com/business/help/120025381414614)
- [Message Template Guidelines](https://www.facebook.com/business/help/103263474314757)
- [WhatsApp Commerce Policy](https://www.facebook.com/business/help/2051161347335290)

---

## 🚀 **NEXT STEPS**

1. Complete Meta Business setup (Day 1)
2. Configure webhook endpoint (Day 1-2)
3. Create and submit message templates (Day 2-3)
4. Test integration thoroughly (Day 3-4)
5. Set up monitoring and cost controls (Day 4)
6. Launch to customers (Day 5+)

---

## ⚠️ **IMPORTANT NOTES**

- **Phone Number Porting**: If using existing number, porting takes 7-14 days
- **Template Review**: Can take 1-2 business days per template
- **Compliance**: Follow WhatsApp Commerce Policy strictly
- **Testing**: Always test with approved templates before going live
- **Backup**: Have backup webhook URL ready
- **Documentation**: Keep all API keys and secrets secure

**This setup guide will give you a fully functional WhatsApp Business API integration for Can Can Water Delivery!** 🚀💧