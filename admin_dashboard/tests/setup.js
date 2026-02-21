/**
 * Test Suite Setup
 * Configures testing environment and utilities
 */

require('dotenv').config({ path: '.env.test' });

const { createClient } = require('@supabase/supabase-js');

// Test database configuration
const testSupabaseUrl = process.env.SUPABASE_TEST_URL || 'http://localhost:54321';
const testSupabaseKey = process.env.SUPABASE_TEST_ANON_KEY || 'test-key';

// Create test Supabase client
const testSupabase = createClient(testSupabaseUrl, testSupabaseKey);

// Test data utilities
class TestDataGenerator {
  static generateVendor() {
    return {
      owner_name: 'Test Vendor',
      phone: `+91${Math.floor(9000000000 + Math.random() * 1000000000)}`,
      email: `test.vendor.${Date.now()}@cancan.test`,
      password_hash: '$2b$10$test-hash',
      business_name: 'Test Water Delivery',
      business_category: 'water_can_delivery',
      business_description: 'Test water delivery service',
      address: '123 Test Street, Test City',
      latitude: 28.6139 + (Math.random() - 0.5) * 0.1,
      longitude: 77.2090 + (Math.random() - 0.5) * 0.1,
      service_radius_km: 5,
      is_active: true,
      verification_status: 'verified'
    };
  }

  static generateCustomer() {
    return {
      name: 'Test Customer',
      phone: `+91${Math.floor(8000000000 + Math.random() * 2000000000)}`,
      email: `test.customer.${Date.now()}@cancan.test`,
      address: '456 Customer Lane, Test Area',
      latitude: 28.6139 + (Math.random() - 0.5) * 0.1,
      longitude: 77.2090 + (Math.random() - 0.5) * 0.1,
      total_orders: 0,
      total_spent: 0
    };
  }

  static generateOrder(vendorId, customerId) {
    return {
      order_id: `ORD${Date.now()}${Math.floor(Math.random() * 1000)}`,
      customer_id: customerId,
      vendor_id: vendorId,
      status: 'pending',
      customer_name: 'Test Customer',
      customer_phone: `+91${Math.floor(8000000000 + Math.random() * 2000000000)}`,
      delivery_address: '123 Delivery Street',
      total_items: 2,
      total_amount: 150,
      platform: 'dashboard',
      priority: 'normal'
    };
  }

  static generateProduct() {
    return {
      name: `Test Product ${Date.now()}`,
      category: 'water_can',
      description: 'Test water can product',
      base_price: 50 + Math.floor(Math.random() * 50),
      is_active: true
    };
  }
}

// Test database utilities
class TestDatabase {
  constructor() {
    this.supabase = testSupabase;
  }

  async cleanup() {
    try {
      // Clean up test data in reverse order of dependencies
      console.log('Cleaning up test database...');

      // Delete test orders
      await this.supabase.from('order_history').delete().neq('customer_phone', null);
      await this.supabase.from('order_items').delete().neq('customer_phone', null);
      await this.supabase.from('orders').delete().neq('customer_phone', null);

      // Delete test customers
      await this.supabase.from('customers').delete().like('phone', '%test.%');

      // Delete test vendors
      await this.supabase.from('vendor_locations').delete().neq('vendor_id', null);
      await this.supabase.from('vendors').delete().like('email', '%test.%');

      // Delete test products
      await this.supabase.from('products').delete().like('name', '%Test Product%');

      // Delete test admin users
      await this.supabase.from('admin_users').delete().like('email', '%test.%');

      console.log('Test database cleanup completed');
    } catch (error) {
      console.error('Error during cleanup:', error);
    }
  }

  async setupTestData() {
    try {
      console.log('Setting up test data...');

      // Create test admin user
      const { data: adminUser } = await this.supabase
        .from('admin_users')
        .insert({
          name: 'Test Admin',
          email: 'test.admin@cancan.test',
          password_hash: '$2b$10$test-hash',
          role: 'admin',
          is_active: true
        })
        .single();

      // Create test vendor
      const vendor = TestDataGenerator.generateVendor();
      const { data: createdVendor } = await this.supabase
        .from('vendors')
        .insert(vendor)
        .single();

      // Create test customer
      const customer = TestDataGenerator.generateCustomer();
      const { data: createdCustomer } = await this.supabase
        .from('customers')
        .insert(customer)
        .single();

      // Create test product
      const product = TestDataGenerator.generateProduct();
      const { data: createdProduct } = await this.supabase
        .from('products')
        .insert(product)
        .single();

      // Create test order
      const order = TestDataGenerator.generateOrder(
        createdVendor.id,
        createdCustomer.id
      );
      const { data: createdOrder } = await this.supabase
        .from('orders')
        .insert(order)
        .single();

      // Create order items
      await this.supabase
        .from('order_items')
        .insert({
          order_id: createdOrder.id,
          product_id: createdProduct.id,
          vendor_id: createdVendor.id,
          product_name: createdProduct.name,
          quantity: 2,
          unit_price: createdProduct.base_price,
          total_price: createdProduct.base_price * 2
        });

      return {
        adminUser,
        vendor: createdVendor,
        customer: createdCustomer,
        product: createdProduct,
        order: createdOrder
      };

    } catch (error) {
      console.error('Error setting up test data:', error);
      throw error;
    }
  }

  async getTestData() {
    try {
      const [vendors, customers, orders, products] = await Promise.all([
        this.supabase.from('vendors').select('*'),
        this.supabase.from('customers').select('*'),
        this.supabase.from('orders').select('*'),
        this.supabase.from('products').select('*')
      ]);

      return {
        vendors: vendors.data || [],
        customers: customers.data || [],
        orders: orders.data || [],
        products: products.data || []
      };
    } catch (error) {
      console.error('Error getting test data:', error);
      throw error;
    }
  }
}

// HTTP test utilities
class TestUtils {
  static async makeRequest(url, options = {}) {
    const defaultOptions = {
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token'
      }
    };

    const finalOptions = { ...defaultOptions, ...options };

    try {
      const response = await fetch(url, finalOptions);
      const data = await response.json();

      return {
        success: response.ok,
        status: response.status,
        statusText: response.statusText,
        data,
        headers: response.headers
      };
    } catch (error) {
      return {
        success: false,
        error: error.message,
        status: 0,
        statusText: 'Network Error'
      };
    }
  }

  static async get(url, token = null) {
    return this.makeRequest(url, {
      method: 'GET',
      headers: token ? { 'Authorization': `Bearer ${token}` } : {}
    });
  }

  static async post(url, data, token = null) {
    return this.makeRequest(url, {
      method: 'POST',
      body: JSON.stringify(data),
      headers: token ? { 'Authorization': `Bearer ${token}` } : {}
    });
  }

  static async put(url, data, token = null) {
    return this.makeRequest(url, {
      method: 'PUT',
      body: JSON.stringify(data),
      headers: token ? { 'Authorization': `Bearer ${token}` } : {}
    });
  }

  static async delete(url, token = null) {
    return this.makeRequest(url, {
      method: 'DELETE',
      headers: token ? { 'Authorization': `Bearer ${token}` } : {}
    });
  }

  // WebSocket test utilities
  static async createWebSocketConnection(url, protocols = []) {
    return new Promise((resolve, reject) => {
      const ws = new (require('ws'))(protocols ? `${url}?${protocols.join(',')}` : url);

      ws.on('open', () => {
        resolve(ws);
      });

      ws.on('error', (error) => {
        reject(error);
      });

      // Timeout after 5 seconds
      setTimeout(() => {
        if (ws.readyState === 0 || ws.readyState === 1) {
          reject(new Error('WebSocket connection timeout'));
        }
      }, 5000);
    });
  }

  // File upload test utilities
  static createTestFile(content, filename, mimeType = 'text/plain') {
    const blob = new Blob([content], { type: mimeType });
    return new File([blob], filename, { type: mimeType });
  }

  // Date utilities
  static createFutureDate(minutes = 30) {
    const date = new Date();
    date.setMinutes(date.getMinutes() + minutes);
    return date;
  }

  static createPastDate(days = 1) {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return date;
  }

  // Random data generators
  static randomId() {
    return Math.random().toString(36).substring(2, 15);
  }

  static randomEmail() {
    return `test.${this.randomId()}@cancan.test`;
  }

  static randomPhone() {
    return `+91${Math.floor(8000000000 + Math.random() * 2000000000)}`;
  }

  // Test assertions
  static assert(condition, message) {
    if (!condition) {
      throw new Error(`Assertion failed: ${message}`);
    }
  }

  static assertEqual(actual, expected, message) {
    if (actual !== expected) {
      throw new Error(`Assertion failed: ${message}. Expected: ${expected}, Actual: ${actual}`);
    }
  }

  static assertContains(text, substring, message) {
    if (!text.includes(substring)) {
      throw new Error(`Assertion failed: ${message}. Text "${text}" does not contain "${substring}"`);
    }
  }

  static assertType(value, type, message) {
    const actualType = Array.isArray(value) ? 'array' : typeof value;
    if (actualType !== type) {
      throw new Error(`Assertion failed: ${message}. Expected type: ${type}, Actual type: ${actualType}`);
    }
  }
}

// Performance testing utilities
class PerformanceTestUtils {
  static async measureTime(fn, iterations = 1) {
    const start = Date.now();

    for (let i = 0; i < iterations; i++) {
      await fn();
    }

    const end = Date.now();
    return {
      totalTime: end - start,
      averageTime: (end - start) / iterations,
      iterations
    };
  }

  static async measureMemoryUsage(fn) {
    const beforeMemory = process.memoryUsage();
    await fn();
    const afterMemory = process.memoryUsage();

    return {
      heapUsed: afterMemory.heapUsed - beforeMemory.heapUsed,
      heapTotal: afterMemory.heapTotal - beforeMemory.heapTotal,
      rss: afterMemory.rss - beforeMemory.rss
    };
  }

  static async measureThroughput(requests, duration = 10000) {
    const start = Date.now();
    const results = [];

    for (let i = 0; i < requests; i++) {
      const requestStart = Date.now();
      // Simulate request (replace with actual request)
      await new Promise(resolve => setTimeout(resolve, 10));
      const requestEnd = Date.now();

      results.push(requestEnd - requestStart);

      // Stop if duration exceeded
      if (Date.now() - start >= duration) {
        break;
      }
    }

    const totalTime = Date.now() - start;
    const successfulRequests = results.length;

    return {
      totalTime,
      successfulRequests,
      averageResponseTime: results.reduce((a, b) => a + b, 0) / results.length,
      throughput: (successfulRequests / totalTime) * 1000 // requests per second
    };
  }
}

module.exports = {
  testSupabase,
  TestDataGenerator,
  TestDatabase,
  TestUtils,
  PerformanceTestUtils
};