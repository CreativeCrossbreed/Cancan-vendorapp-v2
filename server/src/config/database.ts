import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Supabase configuration
const supabaseUrl = process.env.SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'your_anon_key';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'your_service_key';

// Development mode - use local mock if no Supabase configured
const isDevMode = process.env.DEV_MODE === 'true';

// Export both anon and service clients
export const supabase: SupabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true
  }
});

export const supabaseAdmin: SupabaseClient = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
});

// Mock data for development without Supabase
const mockVendors = [
  {
    id: 'dev-vendor-123',
    business_name: 'CanCan Water Services',
    owner_name: 'John Doe',
    phone: '9876543210',
    email: 'john@cancan.com',
    address: '123 Main Street, Bangalore',
    latitude: 12.9716,
    longitude: 77.5946,
    city: 'Bangalore',
    state: 'Karnataka',
    is_active: true,
    is_verified: true,
    rating: 4.5,
    total_orders: 150,
    completed_orders: 145,
    cancelled_orders: 5,
    commission_rate: 10.0,
    created_at: new Date().toISOString()
  }
];

const mockCustomers = [
  {
    id: 'customer-1',
    vendor_id: 'dev-vendor-123',
    name: 'Jane Smith',
    phone: '9123456789',
    address: '456 Oak Street, Bangalore',
    total_orders: 25,
    total_spent: 875.50,
    created_at: new Date().toISOString()
  },
  {
    id: 'customer-2',
    vendor_id: 'dev-vendor-123',
    name: 'Bob Johnson',
    phone: '9234567890',
    address: '789 Pine Avenue, Bangalore',
    total_orders: 18,
    total_spent: 630.00,
    created_at: new Date().toISOString()
  }
];

const mockOrders = [
  {
    id: 'order-1',
    order_number: 'CAN-20241217-0001',
    vendor_id: 'dev-vendor-123',
    customer_id: 'customer-1',
    delivery_date: new Date().toISOString().split('T')[0],
    time_slot: '10 AM - 12 PM',
    status: 'delivered',
    payment_status: 'paid',
    total_amount: 35.00,
    is_delivered: true,
    delivered_at: new Date().toISOString(),
    created_at: new Date().toISOString()
  },
  {
    id: 'order-2',
    order_number: 'CAN-20241217-0002',
    vendor_id: 'dev-vendor-123',
    customer_id: 'customer-2',
    delivery_date: new Date().toISOString().split('T')[0],
    time_slot: '2 PM - 4 PM',
    status: 'pending',
    payment_status: 'pending',
    total_amount: 30.00,
    is_delivered: false,
    created_at: new Date().toISOString()
  }
];

const mockProducts = [
  {
    id: 'product-1',
    name: '20L Mineral Water Can',
    description: 'Standard 20 liter mineral water can',
    category: 'water_can',
    base_price: 30.00,
    is_active: true
  },
  {
    id: 'product-2',
    name: '20L Packaged Drinking Water',
    description: '20 liter packaged drinking water with RO purification',
    category: 'water_can',
    base_price: 25.00,
    is_active: true
  }
];

// Database wrapper that works with both Supabase and mock data
export class DatabaseService {
  private useSupabase: boolean;

  constructor() {
    this.useSupabase = !isDevMode && supabaseUrl !== 'https://your-project.supabase.co';
  }

  // Vendors
  async getVendors() {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('vendors').select('*');
      if (error) throw error;
      return data;
    }
    return mockVendors;
  }

  async getVendorById(id: string) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('vendors').select('*').eq('id', id).single();
      if (error) throw error;
      return data;
    }
    return mockVendors.find(v => v.id === id);
  }

  async getVendorByPhone(phone: string) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('vendors').select('*').eq('phone', phone).single();
      if (error && error.code !== 'PGRST116') throw error; // Ignore "not found" errors
      return data;
    }
    return mockVendors.find(v => v.phone === phone);
  }

  async createVendor(vendor: any) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('vendors').insert(vendor).select().single();
      if (error) throw error;
      return data;
    }
    const newVendor = { ...vendor, id: `vendor-${Date.now()}`, created_at: new Date().toISOString() };
    mockVendors.push(newVendor);
    return newVendor;
  }

  async updateVendor(id: string, updates: any) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('vendors').update(updates).eq('id', id).select().single();
      if (error) throw error;
      return data;
    }
    const index = mockVendors.findIndex(v => v.id === id);
    if (index !== -1) {
      mockVendors[index] = { ...mockVendors[index], ...updates, updated_at: new Date().toISOString() };
      return mockVendors[index];
    }
    throw new Error('Vendor not found');
  }

  // Customers
  async getCustomers(vendorId?: string) {
    if (this.useSupabase) {
      let query = supabaseAdmin.from('customers').select('*');
      if (vendorId) query = query.eq('vendor_id', vendorId);
      const { data, error } = await query;
      if (error) throw error;
      return data;
    }
    return vendorId ? mockCustomers.filter(c => c.vendor_id === vendorId) : mockCustomers;
  }

  async getCustomerById(id: string) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('customers').select('*').eq('id', id).single();
      if (error) throw error;
      return data;
    }
    return mockCustomers.find(c => c.id === id);
  }

  async createCustomer(customer: any) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('customers').insert(customer).select().single();
      if (error) throw error;
      return data;
    }
    const newCustomer = { ...customer, id: `customer-${Date.now()}`, created_at: new Date().toISOString() };
    mockCustomers.push(newCustomer);
    return newCustomer;
  }

  // Orders
  async getOrders(vendorId?: string, status?: string) {
    if (this.useSupabase) {
      let query = supabaseAdmin.from('orders').select(`
        *,
        customers(*)
      `);
      if (vendorId) query = query.eq('vendor_id', vendorId);
      if (status) query = query.eq('status', status);
      const { data, error } = await query.order('created_at', { ascending: false });
      if (error) throw error;
      return data;
    }
    let filteredOrders = mockOrders;
    if (vendorId) filteredOrders = filteredOrders.filter(o => o.vendor_id === vendorId);
    if (status) filteredOrders = filteredOrders.filter(o => o.status === status);
    return filteredOrders.map(order => ({
      ...order,
      customers: mockCustomers.find(c => c.id === order.customer_id)
    }));
  }

  async getOrdersByDateRange(vendorId: string, startDate: string, endDate: string) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin
        .from('orders')
        .select('*')
        .eq('vendor_id', vendorId)
        .gte('delivery_date', startDate)
        .lte('delivery_date', endDate)
        .order('delivery_date', { ascending: true });
      if (error) throw error;
      return data;
    }
    return mockOrders.filter(o =>
      o.vendor_id === vendorId &&
      o.delivery_date >= startDate &&
      o.delivery_date <= endDate
    );
  }

  async createOrder(order: any) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('orders').insert(order).select().single();
      if (error) throw error;
      return data;
    }
    const newOrder = {
      ...order,
      id: `order-${Date.now()}`,
      order_number: `CAN-${new Date().toISOString().slice(0,10).replace(/-/g,'')}-${String(mockOrders.length + 1).padStart(4, '0')}`,
      created_at: new Date().toISOString()
    };
    mockOrders.push(newOrder);
    return newOrder;
  }

  async updateOrderStatus(orderId: string, status: string, additionalData?: any) {
    if (this.useSupabase) {
      const updates = { status, updated_at: new Date().toISOString(), ...additionalData };
      const { data, error } = await supabaseAdmin.from('orders').update(updates).eq('id', orderId).select().single();
      if (error) throw error;
      return data;
    }
    const index = mockOrders.findIndex(o => o.id === orderId);
    if (index !== -1) {
      mockOrders[index] = {
        ...mockOrders[index],
        status,
        updated_at: new Date().toISOString(),
        ...additionalData
      };
      return mockOrders[index];
    }
    throw new Error('Order not found');
  }

  // Products
  async getProducts() {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin.from('products').select('*').eq('is_active', true);
      if (error) throw error;
      return data;
    }
    return mockProducts;
  }

  async getVendorProducts(vendorId: string) {
    if (this.useSupabase) {
      const { data, error } = await supabaseAdmin
        .from('vendor_products')
        .select(`
          *,
          products(*)
        `)
        .eq('vendor_id', vendorId)
        .eq('is_available', true);
      if (error) throw error;
      return data;
    }
    // Return mock vendor products
    return [
      {
        id: 'vp-1',
        vendor_id: vendorId,
        product_id: 'product-1',
        price: 35.00,
        stock_quantity: 100,
        is_available: true,
        products: mockProducts[0]
      },
      {
        id: 'vp-2',
        vendor_id: vendorId,
        product_id: 'product-2',
        price: 30.00,
        stock_quantity: 50,
        is_available: true,
        products: mockProducts[1]
      }
    ];
  }

  // Analytics
  async getVendorAnalytics(vendorId: string, startDate?: string, endDate?: string) {
    if (this.useSupabase) {
      let query = supabaseAdmin
        .from('daily_vendor_analytics')
        .select('*')
        .eq('vendor_id', vendorId);

      if (startDate) query = query.gte('date', startDate);
      if (endDate) query = query.lte('date', endDate);

      const { data, error } = await query.order('date', { ascending: true });
      if (error) throw error;
      return data;
    }

    // Return mock analytics data
    const today = new Date();
    const analytics = [];
    for (let i = 29; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      analytics.push({
        vendor_id: vendorId,
        date: date.toISOString().split('T')[0],
        total_orders: Math.floor(Math.random() * 20) + 5,
        delivered_orders: Math.floor(Math.random() * 18) + 4,
        total_revenue: Math.floor(Math.random() * 1000) + 200,
        total_cans_delivered: Math.floor(Math.random() * 40) + 10
      });
    }
    return analytics;
  }

  // Health check
  async healthCheck(): Promise<boolean> {
    if (this.useSupabase) {
      try {
        const { data, error } = await supabaseAdmin.from('vendors').select('count').limit(1);
        return !error;
      } catch {
        return false;
      }
    }
    return true; // Always healthy in dev mode
  }

  isUsingSupabase(): boolean {
    return this.useSupabase;
  }
}

// Export singleton instance
export const db = new DatabaseService();

// Legacy exports for backward compatibility
export const checkDatabaseConnection = async (): Promise<boolean> => {
  return await db.healthCheck();
};

export const initializeDatabase = async (): Promise<void> => {
  if (db.isUsingSupabase()) {
    console.log('Using Supabase database');
  } else {
    console.log('Using development mock data');
  }
};

export default supabase;