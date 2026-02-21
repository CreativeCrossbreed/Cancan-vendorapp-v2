/**
 * API Unit Tests
 * Test backend API endpoints and services
 */

const request = require('supertest');
const app = require('../server');
const { TestDatabase, TestDataGenerator, TestUtils } = require('../tests/setup');

describe('API Endpoints', () => {
  let testDb;
  let testData;
  let authToken;

  beforeAll(async () => {
    testDb = new TestDatabase();
    await testDb.cleanup();
    testData = await testDb.setupTestData();

    // Get admin token
    const loginResponse = await TestUtils.post('http://localhost:3001/api/auth/login', {
      email: 'test.admin@cancan.test',
      password: 'testpassword'
    });

    if (loginResponse.success) {
      authToken = loginResponse.data.token;
    }
  });

  afterAll(async () => {
    await testDb.cleanup();
  });

  describe('Authentication', () => {
    test('POST /api/auth/login - successful login', async () => {
      const response = await TestUtils.post('http://localhost:3001/api/auth/login', {
        email: 'test.admin@cancan.test',
        password: 'testpassword'
      });

      expect(response.success).toBe(true);
      expect(response.data.admin).toBeDefined();
      expect(response.data.token).toBeDefined();
    });

    test('POST /api/auth/login - invalid credentials', async () => {
      const response = await TestUtils.post('http://localhost:3001/api/auth/login', {
        email: 'invalid@test.com',
        password: 'wrongpassword'
      });

      expect(response.success).toBe(false);
      expect(response.error).toContain('Invalid');
    });

    test('GET /api/auth/verify - successful verification', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/auth/verify', authToken);

      expect(response.success).toBe(true);
      expect(response.data.admin).toBeDefined();
    });

    test('POST /api/auth/logout - successful logout', async () => {
      const response = await TestUtils.post('http://localhost:3001/api/auth/logout', {}, authToken);

      expect(response.success).toBe(true);
    });
  });

  describe('Vendor Management', () => {
    test('GET /api/vendors - get all vendors', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/vendors', authToken);

      expect(response.success).toBe(true);
      expect(Array.isArray(response.data.data)).toBe(true);
      expect(response.data.data.length).toBeGreaterThan(0);
    });

    test('POST /api/vendors - create new vendor', async () => {
      const newVendor = TestDataGenerator.generateVendor();

      const response = await TestUtils.post('http://localhost:3001/api/vendors', newVendor, authToken);

      expect(response.success).toBe(true);
      expect(response.data.business_name).toBe(newVendor.business_name);
      expect(response.data.id).toBeDefined();
    });

    test('GET /api/vendors/:id - get vendor by ID', async () => {
      const response = await TestUtils.get(`http://localhost:3001/api/vendors/${testData.vendor.id}`, authToken);

      expect(response.success).toBe(true);
      expect(response.data.business_name).toBe(testData.vendor.business_name);
    });

    test('PUT /api/vendors/:id/verification - update verification status', async () => {
      const response = await TestUtils.put(
        `http://localhost:3001/api/vendors/${testData.vendor.id}/verification`,
        {
          status: 'verified',
          notes: 'Test verification'
        },
        authToken
      );

      expect(response.success).toBe(true);
    });

    test('PUT /api/vendors/:id/status - toggle vendor status', async () => {
      const response = await TestUtils.put(
        `http://localhost:3001/api/vendors/${testData.vendor.id}/status`,
        {
          isActive: false,
          reason: 'Test deactivation'
        },
        authToken
      );

      expect(response.success).toBe(true);
    });

    test('GET /api/vendors/statistics - get vendor statistics', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/vendors/statistics', authToken);

      expect(response.success).toBe(true);
      expect(response.data.total).toBeDefined();
      expect(response.data.active).toBeDefined();
    });
  });

  describe('Order Management', () => {
    test('GET /api/orders - get all orders', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/orders', authToken);

      expect(response.success).toBe(true);
      expect(Array.isArray(response.data.data)).toBe(true);
    });

    test('POST /api/orders - create new order', async () => {
      const newOrder = TestDataGenerator.generateOrder(testData.vendor.id, testData.customer.id);

      const response = await TestUtils.post('http://localhost:3001/api/orders', newOrder, authToken);

      expect(response.success).toBe(true);
      expect(response.data.orderId).toBeDefined();
    });

    test('GET /api/orders/:id - get order by ID', async () => {
      const response = await TestUtils.get(`http://localhost:3001/api/orders/${testData.order.id}`, authToken);

      expect(response.success).toBe(true);
      expect(response.data.orderId).toBe(testData.order.orderId);
    });

    test('PUT /api/orders/:id/status - update order status', async () => {
      const response = await TestUtils.put(
        `http://localhost:3001/api/orders/${testData.order.id}/status`,
        {
          status: 'confirmed',
          notes: 'Test status update'
        },
        authToken
      );

      expect(response.success).toBe(true);
    });

    test('PUT /api/orders/:id/assign - assign order to vendor', async () => {
      const response = await TestUtils.put(
        `http://localhost:3001/api/orders/${testData.order.id}/assign`,
        {
          vendorId: testData.vendor.id,
          estimatedDeliveryTime: TestUtils.createFutureDate(45)
        },
        authToken
      );

      expect(response.success).toBe(true);
    });
  });

  describe('Customer Management', () => {
    test('GET /api/customers - get all customers', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/customers', authToken);

      expect(response.success).toBe(true);
      expect(Array.isArray(response.data.data)).toBe(true);
    });

    test('POST /api/customers - create new customer', async () => {
      const newCustomer = TestDataGenerator.generateCustomer();

      const response = await TestUtils.post('http://localhost:3001/api/customers', newCustomer, authToken);

      expect(response.success).toBe(true);
      expect(response.data.name).toBe(newCustomer.name);
    });

    test('GET /api/customers/:id - get customer by ID', async () => {
      const response = await TestUtils.get(`http://localhost:3001/api/customers/${testData.customer.id}`, authToken);

      expect(response.success).toBe(true);
      expect(response.data.name).toBe(testData.customer.name);
    });

    test('PUT /api/customers/:id - update customer', async () => {
      const updateData = {
        name: 'Updated Customer Name',
        address: 'Updated Address'
      };

      const response = await TestUtils.put(
        `http://localhost:3001/api/customers/${testData.customer.id}`,
        updateData,
        authToken
      );

      expect(response.success).toBe(true);
    });
  });

  describe('Location Services', () => {
    test('POST /api/vendors/:id/location - update vendor location', async () => {
      const locationData = {
        latitude: 28.6139,
        longitude: 77.2090,
        accuracy: 10,
        location_method: 'gps'
      };

      const response = await TestUtils.post(
        `http://localhost:3001/api/vendors/${testData.vendor.id}/location`,
        locationData
      );

      expect(response.success).toBe(true);
    });

    test('GET /api/vendors/:id/location - get vendor location', async () => {
      const response = await TestUtils.get(`http://localhost:3001/api/vendors/${testData.vendor.id}/location`);

      expect(response.success).toBe(true);
      expect(response.data.latitude).toBeDefined();
      expect(response.data.longitude).toBeDefined();
    });

    test('GET /api/vendors/nearby - find nearby vendors', async () => {
      const response = await TestUtils.get(
        'http://localhost:3001/api/vendors/nearby?latitude=28.6139&longitude=77.2090&radiusKm=10&limit=5'
      );

      expect(response.success).toBe(true);
      expect(Array.isArray(response.data)).toBe(true);
    });
  });

  describe('WhatsApp Integration', () => {
    test('POST /api/webhooks/whatsapp - process WhatsApp webhook', async () => {
      const webhookData = {
        object: 'whatsapp_business_account',
        entry: [{
          id: 'test-entry-id',
          changes: [{
            value: {
              messaging_product: 'whatsapp',
              messages: [{
                from: '+919876543210',
                id: 'test-message-id',
                timestamp: Date.now(),
                text: {
                  body: 'Test message'
                },
                type: 'text'
              }]
            }]
          }]
        }]
      };

      const response = await request(app)
        .post('/api/webhooks/whatsapp')
        .send(webhookData);

      expect(response.status).toBe(200);
    });

    test('POST /api/whatsapp/test - test WhatsApp message', async () => {
      const testData = {
        message: 'Test message for WhatsApp',
        phone: '+919876543210'
      };

      const response = await TestUtils.post('http://localhost:3001/api/whatsapp/test', testData, authToken);

      expect(response.success).toBe(true);
      expect(response.response).toBeDefined();
    });
  });

  describe('Analytics', () => {
    test('GET /api/analytics/dashboard - get dashboard analytics', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/analytics/dashboard', authToken);

      expect(response.success).toBe(true);
      expect(response.data.overview).toBeDefined();
    });

    test('GET /api/analytics/revenue - get revenue analytics', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/analytics/revenue', authToken);

      expect(response.success).toBe(true);
      expect(Array.isArray(response.data.daily)).toBe(true);
    });

    test('GET /api/analytics/vendors - get vendor analytics', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/analytics/vendors', authToken);

      expect(response.success).toBe(true);
      expect(Array.isArray(response.data.performance)).toBe(true);
    });
  });

  describe('Health Check', () => {
    test('GET /api/health - health check', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/health');

      expect(response.success).toBe(true);
      expect(response.data.message).toBe('Can Can Admin API is running');
      expect(response.data.version).toBe('1.0.0');
    });
  });

  describe('Error Handling', () => {
    test('GET /api/nonexistent - should return 404', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/nonexistent', authToken);

      expect(response.status).toBe(404);
    });

    test('POST /api/auth/login - missing required fields', async () => {
      const response = await TestUtils.post('http://localhost:3001/api/auth/login', {
        email: 'test@test.com'
        // Missing password
      });

      expect(response.success).toBe(false);
      expect(response.error).toContain('required');
    });

    test('GET /api/vendors - unauthorized access', async () => {
      const response = await TestUtils.get('http://localhost:3001/api/vendors', null); // No token

      expect(response.status).toBe(401);
    });
  });
});