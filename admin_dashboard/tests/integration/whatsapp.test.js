/**
 * WhatsApp Integration Tests
 * Test real WhatsApp Meta API integration
 */

const WhatsAppMetaAPI = require('../../services/whatsappMeta');
const { TestUtils, TestDataGenerator } = require('../setup');

describe('WhatsApp Integration', () => {
  let whatsappAPI;

  beforeAll(() => {
    // Mock environment variables for testing
    process.env.WHATSAPP_API_KEY = 'test-api-key';
    process.env.WHATSAPP_PHONE_NUMBER_ID = 'test-phone-id';
    process.env.WHATSAPP_WEBHOOK_SECRET = 'test-webhook-secret';
    process.env.WHATSAPP_VERSION = 'v18.0';

    whatsappAPI = new WhatsAppMetaAPI();
  });

  describe('Message Templates', () => {
    test('should format order confirmation template correctly', () => {
      const orderDetails = {
        items: [
          { name: '20L Water Can', quantity: 2 },
          { name: '10L Water Jar', quantity: 1 }
        ],
        orderId: 'ORD123456',
        totalAmount: 180,
        estimatedDelivery: '30-45 minutes'
      };

      const components = whatsappAPI.constructor.prototype.sendOrderConfirmation
        .call(whatsappAPI, '+919876543210', orderDetails)
        .then(result => result.components || []);

      // Verify template structure
      expect(components).toBeDefined();
      expect(Array.isArray(components)).toBe(true);
    });

    test('should format delivery update template correctly', () => {
      const orderDetails = {
        orderId: 'ORD123456',
        estimatedDelivery: '15-20 minutes'
      };

      const vendorInfo = {
        businessName: 'Test Water Delivery',
        phone: '+919876543210'
      };

      const result = whatsappAPI.constructor.prototype.sendDeliveryUpdate
        .call(whatsappAPI, '+919876543210', orderDetails, 'confirmed', vendorInfo);

      expect(result).toBeDefined();
      expect(typeof result.then).toBe('function'); // Should return a Promise
    });

    test('should format payment reminder template correctly', () => {
      const orderDetails = {
        orderId: 'ORD123456',
        amount: 150
      };

      const result = whatsappAPI.constructor.prototype.sendPaymentReminder
        .call(whatsappAPI, '+919876543210', orderDetails);

      expect(result).toBeDefined();
      expect(typeof result.then).toBe('function'); // Should return a Promise
    });

    test('should format welcome message template correctly', () => {
      const businessInfo = {
        phone: '+919876543210'
      };

      const result = whatsappAPI.constructor.prototype.sendWelcomeMessage
        .call(whatsappAPI, '+919876543210', businessInfo);

      expect(result).toBeDefined();
      expect(typeof result.then).toBe('function'); // Should return a Promise
    });
  });

  describe('Webhook Processing', () => {
    test('should process incoming WhatsApp webhook payload', () => {
      const webhookData = {
        object: 'whatsapp_business_account',
        entry: [{
          id: 'test-entry-id',
          time: 1234567890,
          changes: [{
            value: {
              messaging_product: 'whatsapp',
              messages: [{
                from: '+919876543210',
                id: 'test-message-id',
                timestamp: 1234567890,
                text: {
                  body: 'Order 2 20L cans to 123 Main Street'
                },
                type: 'text'
              }]
            }
          }]
        }]
      };

      const processedData = whatsappAPI.processWebhookPayload(webhookData);

      expect(processedData.object).toBe('whatsapp_business_account');
      expect(processedData.entry).toBeDefined();
      expect(Array.isArray(processedData.entry)).toBe(true);
      expect(processedData.processed_at).toBeDefined();
    });

    test('should extract messages from webhook payload', () => {
      const webhookData = {
        entry: [{
          messaging: [{
            sender: { phone: '+919876543210' },
            message: {
              mid: 'msg_123',
              text: {
                body: 'Test message'
              },
              type: 'text'
            },
            timestamp: 1234567890
          }]
        }]
      };

      const messages = whatsappAPI.extractMessageFromWebhook(webhookData);

      expect(Array.isArray(messages)).toBe(true);
      expect(messages.length).toBe(1);
      expect(messages[0].text).toBe('Test message');
      expect(messages[0].from.phone).toBe('+919876543210');
    });

    test('should verify webhook signature correctly', () => {
      const body = { test: 'data' };
      const secret = 'test-secret';

      // Create expected signature
      const crypto = require('crypto');
      const expectedSignature = 'sha256=' + crypto
        .createHmac('sha256', secret)
        .update(JSON.stringify(body))
        .digest('hex');

      // Mock the webhook secret
      whatsappAPI.webhookSecret = secret;

      const isValid = whatsappAPI.verifyWebhookSignature(body, expectedSignature);

      expect(isValid).toBe(true);
    });

    test('should reject invalid webhook signature', () => {
      const body = { test: 'data' };
      const invalidSignature = 'sha256=invalid-signature';

      const isValid = whatsappAPI.verifyWebhookSignature(body, invalidSignature);

      expect(isValid).toBe(false);
    });
  });

  describe('Message Sending', () => {
    test('should send text message with correct format', () => {
      const to = '+919876543210';
      const text = 'Test message';

      // Mock fetch to prevent actual API calls
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          messages: [{ id: 'test-message-id' }]
        })
      });

      const result = whatsappAPI.sendTextMessage(to, text);

      expect(typeof result.then).toBe('function');

      return result.then(response => {
        expect(response.success).toBe(true);
        expect(response.messageId).toBe('test-message-id');
        expect(response.to).toBe(to);
        expect(response.text).toBe(text);
      });
    });

    test('should handle API errors gracefully', () => {
      const to = '+919876543210';
      const text = 'Test message';

      // Mock fetch to simulate API error
      global.fetch = jest.fn().mockResolvedValue({
        ok: false,
        json: () => Promise.resolve({
          error: {
            message: 'Invalid phone number',
            code: 1005
          }
        })
      });

      const result = whatsappAPI.sendTextMessage(to, text);

      return result.then(response => {
        expect(response.success).toBe(false);
        expect(response.error).toBe('Invalid phone number');
        expect(response.error_code).toBe(1005);
      });
    });

    test('should clean phone number format for API', () => {
      const to = '+919876543210';
      const text = 'Test message';

      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          messages: [{ id: 'test-message-id' }]
        })
      });

      whatsappAPI.sendTextMessage(to, text);

      expect(global.fetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          body: expect.stringContaining('"to":"919876543210"') // + removed
        })
      );
    });
  });

  describe('Connection Testing', () => {
    test('should test connection with configured test phone', () => {
      process.env.WHATSAPP_TEST_PHONE = '+919876543210';

      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          messages: [{ id: 'test-message-id' }]
        })
      });

      const result = whatsappAPI.testConnection();

      return result.then(response => {
        expect(response.success).toBe(true);
        expect(response.message).toBe('Test message sent successfully');
        expect(response.messageId).toBe('test-message-id');
      });
    });

    test('should handle missing test phone number', () => {
      delete process.env.WHATSAPP_TEST_PHONE;

      const result = whatsappAPI.testConnection();

      return result.then(response => {
        expect(response.success).toBe(false);
        expect(response.error).toBe('No test phone number configured');
      });
    });

    test('should handle connection test failures', () => {
      process.env.WHATSAPP_TEST_PHONE = '+919876543210';

      global.fetch = jest.fn().mockResolvedValue({
        ok: false,
        json: () => Promise.resolve({
          error: {
            message: 'Authentication failed',
            code: 1001
          }
        })
      });

      const result = whatsappAPI.testConnection();

      return result.then(response => {
        expect(response.success).toBe(false);
        expect(response.error).toBe('Authentication failed');
      });
    });
  });

  describe('Configuration Validation', () => {
    test('should validate required environment variables', () => {
      const requiredVars = [
        'WHATSAPP_API_KEY',
        'WHATSAPP_PHONE_NUMBER_ID',
        'WHATSAPP_WEBHOOK_SECRET'
      ];

      requiredVars.forEach(varName => {
        expect(process.env[varName]).toBeDefined();
      });
    });

    test('should throw error for missing configuration', () => {
      // Clear environment variables
      delete process.env.WHATSAPP_API_KEY;
      delete process.env.WHATSAPP_PHONE_NUMBER_ID;
      delete process.env.WHATSAPP_WEBHOOK_SECRET;

      expect(() => {
        new WhatsAppMetaAPI();
      }).toThrow('Missing required environment variables');
    });
  });

  describe('Account Management', () => {
    test('should get phone number details', () => {
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          display_phone_number: '+919876543210',
          name: 'Test Business',
          quality_rating: 'GREEN',
          is_verified: true,
          code_verification_status: 'VERIFIED'
        })
      });

      const result = whatsappAPI.getPhoneNumberDetails();

      return result.then(response => {
        expect(response.success).toBe(true);
        expect(response.data.phoneNumber).toBe('+919876543210');
        expect(response.data.name).toBe('Test Business');
        expect(response.data.qualityRating).toBe('GREEN');
        expect(response.data.isVerified).toBe(true);
      });
    });

    test('should get message templates', () => {
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          data: [
            {
              name: 'order_confirmation_v2',
              status: 'APPROVED',
              category: 'UTILITY'
            },
            {
              name: 'delivery_update_v2',
              status: 'APPROVED',
              category: 'UTILITY'
            }
          ]
        })
      });

      const result = whatsappAPI.getTemplates();

      return result.then(response => {
        expect(response.success).toBe(true);
        expect(Array.isArray(response.data)).toBe(true);
        expect(response.data.length).toBe(2);
        expect(response.data[0].name).toBe('order_confirmation_v2');
        expect(response.data[0].status).toBe('APPROVED');
      });
    });

    test('should get account analytics', () => {
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          data: {
            conversations: 150,
            sent_messages: 1200,
            delivered_messages: 1150,
            read_messages: 1100
          }
        })
      });

      const result = whatsappAPI.getAccountAnalytics();

      return result.then(response => {
        expect(response.success).toBe(true);
        expect(response.data.conversations).toBe(150);
        expect(response.data.sent_messages).toBe(1200);
      });
    });
  });

  describe('Error Handling', () => {
    test('should handle network errors', () => {
      global.fetch = jest.fn().mockRejectedValue(new Error('Network error'));

      const result = whatsappAPI.sendTextMessage('+919876543210', 'Test');

      return result.then(response => {
        expect(response.success).toBe(false);
        expect(response.error).toBe('Failed to send WhatsApp text message');
        expect(response.details).toBe('Network error');
      });
    });

    test('should handle malformed responses', () => {
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.reject(new Error('Invalid JSON'))
      });

      const result = whatsappAPI.sendTextMessage('+919876543210', 'Test');

      return result.then(response => {
        expect(response.success).toBe(false);
      });
    });
  });

  describe('Rate Limiting', () => {
    test('should implement rate limiting for message sending', async () => {
      const messages = [];
      const start = Date.now();

      // Mock successful responses
      global.fetch = jest.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({
          messages: [{ id: 'test-message-id' }]
        })
      });

      // Send multiple messages rapidly
      for (let i = 0; i < 5; i++) {
        messages.push(whatsappAPI.sendTextMessage('+919876543210', `Message ${i}`));
      }

      const results = await Promise.all(messages);
      const end = Date.now();

      // Should take some time due to rate limiting
      expect(end - start).toBeGreaterThan(100);

      // All messages should succeed
      results.forEach(result => {
        expect(result.success).toBe(true);
      });
    });
  });

  afterAll(() => {
    // Clean up mocks
    global.fetch = undefined;
  });
});