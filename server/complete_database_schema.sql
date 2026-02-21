-- Complete Database Schema for Can Can Vendor App & Dashboard
-- This schema supports both the mobile app and admin dashboard

-- ============================================
-- VENDOR MANAGEMENT TABLES
-- ============================================

-- Vendors table - Water can delivery vendors
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- Supabase auth user ID
  business_name VARCHAR(255) NOT NULL,
  owner_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255),
  address TEXT NOT NULL,
  flat_number VARCHAR(50),
  floor VARCHAR(20),
  building_name VARCHAR(255),
  landmark VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  city VARCHAR(100),
  state VARCHAR(100),
  pincode VARCHAR(10),

  -- Business details
  gst_number VARCHAR(50),
  fssai_license VARCHAR(100),
  business_hours JSONB DEFAULT '{"monday":{"open":"09:00","close":"21:00"},"tuesday":{"open":"09:00","close":"21:00"},"wednesday":{"open":"09:00","close":"21:00"},"thursday":{"open":"09:00","close":"21:00"},"friday":{"open":"09:00","close":"21:00"},"saturday":{"open":"09:00","close":"21:00"},"sunday":{"open":"09:00","close":"21:00"}}',
  service_areas TEXT[], -- Array of service area names/pincodes

  -- Status and verification
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  is_on_vacation BOOLEAN DEFAULT false,
  vacation_reason TEXT,
  vacation_end_date TIMESTAMP WITH TIME ZONE,

  -- Performance metrics
  rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  total_orders INTEGER DEFAULT 0,
  completed_orders INTEGER DEFAULT 0,
  cancelled_orders INTEGER DEFAULT 0,
  average_delivery_time INTEGER DEFAULT 30, -- in minutes

  -- Financial details
  commission_rate DECIMAL(5,2) DEFAULT 10.0 CHECK (commission_rate >= 0 AND commission_rate <= 100),
  wallet_balance DECIMAL(10,2) DEFAULT 0.0,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_order_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- PRODUCT & INVENTORY TABLES
-- ============================================

-- Products master table
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) DEFAULT 'water_can', -- water_can, accessory, etc.
  base_price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Vendor-specific products and pricing
CREATE TABLE IF NOT EXISTS vendor_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INTEGER DEFAULT 0,
  min_stock_alert INTEGER DEFAULT 10,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(vendor_id, product_id)
);

-- Inventory transactions
CREATE TABLE IF NOT EXISTS inventory_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('stock_in', 'stock_out', 'adjustment')),
  quantity INTEGER NOT NULL,
  remaining_stock INTEGER NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- CUSTOMER MANAGEMENT TABLES
-- ============================================

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(255),

  -- Address details
  address TEXT NOT NULL,
  flat_number VARCHAR(50),
  floor VARCHAR(20),
  building_name VARCHAR(255),
  landmark VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),

  -- Customer preferences and status
  preferred_delivery_time VARCHAR(50),
  notes TEXT,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blocked')),

  -- Analytics data
  total_orders INTEGER DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0.0,
  last_order_at TIMESTAMP WITH TIME ZONE,
  average_order_value DECIMAL(10,2) DEFAULT 0.0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Customer addresses (multiple delivery addresses)
CREATE TABLE IF NOT EXISTS customer_addresses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  address_type VARCHAR(20) DEFAULT 'home' CHECK (address_type IN ('home', 'office', 'other')),
  address TEXT NOT NULL,
  flat_number VARCHAR(50),
  floor VARCHAR(20),
  building_name VARCHAR(255),
  landmark VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- ORDER MANAGEMENT TABLES
-- ============================================

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number VARCHAR(50) UNIQUE NOT NULL, -- Format: CAN-YYYYMMDD-XXXX
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,

  -- Order details
  delivery_date DATE NOT NULL,
  time_slot VARCHAR(50) NOT NULL,
  delivery_address TEXT,

  -- Order status
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled', 'returned')),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
  payment_method VARCHAR(20) CHECK (payment_method IN ('cash', 'upi', 'card', 'wallet')),

  -- Order values
  subtotal DECIMAL(10,2) NOT NULL,
  delivery_fee DECIMAL(10,2) DEFAULT 0.0,
  tax_amount DECIMAL(10,2) DEFAULT 0.0,
  discount_amount DECIMAL(10,2) DEFAULT 0.0,
  total_amount DECIMAL(10,2) NOT NULL,

  -- Delivery tracking
  is_delivered BOOLEAN DEFAULT false,
  delivered_at TIMESTAMP WITH TIME ZONE,
  delivery_otp VARCHAR(6),
  delivery_notes TEXT,

  -- Cancellation details
  cancellation_reason TEXT,
  cancelled_at TIMESTAMP WITH TIME ZONE,
  cancelled_by UUID REFERENCES vendors(id),

  -- Payment timestamps
  payment_marked_at TIMESTAMP WITH TIME ZONE,
  payment_method_details JSONB,

  -- Additional information
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  vendor_product_id UUID REFERENCES vendor_products(id) ON DELETE CASCADE,
  product_name VARCHAR(255) NOT NULL, -- Denormalized for history
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- PAYMENT & TRANSACTION TABLES
-- ============================================

-- Payment records
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  payment_method VARCHAR(20) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  transaction_id VARCHAR(255),
  gateway_response JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Vendor wallet transactions
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('credit', 'debit', 'commission', 'refund')),
  amount DECIMAL(10,2) NOT NULL,
  balance_after DECIMAL(10,2) NOT NULL,
  description TEXT,
  reference_id UUID, -- Reference to order, payment, etc.
  reference_type VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- ANALYTICS & REPORTING TABLES
-- ============================================

-- Daily vendor analytics
CREATE TABLE IF NOT EXISTS daily_vendor_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_orders INTEGER DEFAULT 0,
  delivered_orders INTEGER DEFAULT 0,
  cancelled_orders INTEGER DEFAULT 0,
  total_revenue DECIMAL(10,2) DEFAULT 0.0,
  total_cans_delivered INTEGER DEFAULT 0,
  average_order_value DECIMAL(10,2) DEFAULT 0.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(vendor_id, date)
);

-- Customer analytics
CREATE TABLE IF NOT EXISTS customer_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  orders_placed INTEGER DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0.0,
  last_order_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(customer_id, date)
);

-- ============================================
-- VENDOR RATINGS & REVIEWS
-- ============================================

-- Vendor ratings
CREATE TABLE IF NOT EXISTS vendor_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,
  response TEXT, -- Vendor's response to review
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- ADMIN DASHBOARD TABLES
-- ============================================

-- Admin users table for dashboard authentication
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'operations' CHECK (role IN ('super_admin', 'operations', 'support', 'readonly')),
  permissions JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_login TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true
);

-- Commission tracking table
CREATE TABLE IF NOT EXISTS commission_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  commission_amount DECIMAL(10,2) NOT NULL,
  order_amount DECIMAL(10,2) NOT NULL,
  commission_rate DECIMAL(5,2) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processed', 'paid')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  paid_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- WHATSAPP INTEGRATION TABLES
-- ============================================

-- WhatsApp configuration table
CREATE TABLE IF NOT EXISTS whatsapp_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  api_key VARCHAR(500) NOT NULL,
  webhook_secret VARCHAR(255) NOT NULL,
  phone_number_id VARCHAR(100) NOT NULL,
  business_account_id VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Message logs table for WhatsApp
CREATE TABLE IF NOT EXISTS whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id VARCHAR(255) UNIQUE NOT NULL,
  customer_phone VARCHAR(20) NOT NULL,
  vendor_id UUID REFERENCES vendors(id),
  message_type VARCHAR(50) NOT NULL,
  message_content TEXT,
  direction VARCHAR(20) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  status VARCHAR(50) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- WhatsApp orders table for tracking orders from WhatsApp
CREATE TABLE IF NOT EXISTS whatsapp_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES whatsapp_messages(id),
  customer_id UUID REFERENCES customers(id),
  parsed_quantity INTEGER,
  parsed_product VARCHAR(255),
  status VARCHAR(50) NOT NULL,
  assigned_vendor_id UUID REFERENCES vendors(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- NOTIFICATIONS & LOGGING TABLES
-- ============================================

-- Push notification logs
CREATE TABLE IF NOT EXISTS notification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID, -- Can be vendor or customer
  user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('vendor', 'customer')),
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  notification_type VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'sent',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Audit log for tracking changes
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name VARCHAR(100) NOT NULL,
  record_id UUID NOT NULL,
  action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  old_values JSONB,
  new_values JSONB,
  changed_by UUID, -- Admin user ID
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Vendors indexes
CREATE INDEX IF NOT EXISTS idx_vendors_phone ON vendors(phone);
CREATE INDEX IF NOT EXISTS idx_vendors_email ON vendors(email);
CREATE INDEX IF NOT EXISTS idx_vendors_location ON vendors(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_vendors_active ON vendors(is_active);

-- Customers indexes
CREATE INDEX IF NOT EXISTS idx_customers_vendor_id ON customers(vendor_id);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_vendor_phone ON customers(vendor_id, phone);

-- Orders indexes
CREATE INDEX IF NOT EXISTS idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(delivery_date);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_date ON orders(vendor_id, delivery_date);
CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number);

-- Order items indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_daily_analytics_vendor_date ON daily_vendor_analytics(vendor_id, date);

-- Ratings indexes
CREATE INDEX IF NOT EXISTS idx_ratings_vendor_id ON vendor_ratings(vendor_id);

-- Audit logs indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_record ON audit_logs(table_name, record_id);

-- ============================================
-- TRIGGERS FOR AUTOMATION
-- ============================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vendor_products_updated_at BEFORE UPDATE ON vendor_products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update vendor metrics when order status changes
CREATE OR REPLACE FUNCTION update_vendor_metrics()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        -- Update order counts based on status change
        IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
            UPDATE vendors
            SET
                completed_orders = completed_orders + 1,
                last_order_at = now()
            WHERE id = NEW.vendor_id;
        ELSIF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
            UPDATE vendors
            SET cancelled_orders = cancelled_orders + 1
            WHERE id = NEW.vendor_id;
        ELSIF OLD.status = 'cancelled' AND NEW.status != 'cancelled' THEN
            UPDATE vendors
            SET cancelled_orders = cancelled_orders - 1
            WHERE id = NEW.vendor_id;
        ELSIF OLD.status = 'delivered' AND NEW.status != 'delivered' THEN
            UPDATE vendors
            SET completed_orders = completed_orders - 1
            WHERE id = NEW.vendor_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_vendor_order_metrics
    AFTER UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_vendor_metrics();

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- Vendor performance view
CREATE OR REPLACE VIEW vendor_performance AS
SELECT
    v.id,
    v.business_name,
    v.owner_name,
    v.phone,
    v.rating,
    v.total_orders,
    v.completed_orders,
    v.cancelled_orders,
    CASE
        WHEN v.total_orders > 0 THEN
            ROUND((v.completed_orders::decimal / v.total_orders::decimal) * 100, 2)
        ELSE 0
    END as completion_rate,
    COALESCE(SUM(o.total_amount), 0) as total_revenue,
    COALESCE(AVG(o.total_amount), 0) as average_order_value,
    v.created_at
FROM vendors v
LEFT JOIN orders o ON v.id = o.vendor_id AND o.status = 'delivered'
GROUP BY v.id, v.business_name, v.owner_name, v.phone, v.rating,
         v.total_orders, v.completed_orders, v.cancelled_orders, v.created_at;

-- Customer order summary view
CREATE OR REPLACE VIEW customer_order_summary AS
SELECT
    c.id,
    c.vendor_id,
    c.name,
    c.phone,
    c.total_orders,
    c.total_spent,
    c.average_order_value,
    c.last_order_at,
    COUNT(o.id) as recent_orders_30d,
    COALESCE(SUM(o.total_amount), 0) as recent_spent_30d
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
    AND o.created_at >= now() - interval '30 days'
    AND o.status = 'delivered'
GROUP BY c.id, c.vendor_id, c.name, c.phone, c.total_orders,
         c.total_spent, c.average_order_value, c.last_order_at;

-- ============================================
-- SAMPLE DATA INSERTION
-- ============================================

-- Insert sample products
INSERT INTO products (name, description, category, base_price) VALUES
('20L Mineral Water Can', 'Standard 20 liter mineral water can', 'water_can', 30.00),
('20L Packaged Drinking Water', '20 liter packaged drinking water with RO purification', 'water_can', 25.00),
('10L Mineral Water Can', 'Compact 10 liter mineral water can', 'water_can', 20.00),
('Water Dispenser', 'Hot and cold water dispenser with cooling function', 'accessory', 1500.00),
('Water Can Holder', 'Sturdy plastic holder for water cans', 'accessory', 150.00)
ON CONFLICT DO NOTHING;

-- Insert default admin user (password: admin123)
INSERT INTO admin_users (email, password, role) VALUES
('admin@cancan.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/8xq9cLKSa', 'super_admin'),
('ops@cancan.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/8xq9cLKSa', 'operations'),
('support@cancan.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/8xq9cLKSa', 'support')
ON CONFLICT (email) DO NOTHING;

-- Insert default WhatsApp config
INSERT INTO whatsapp_config (api_key, webhook_secret, phone_number_id, business_account_id) VALUES
('your_whatsapp_api_token_here', 'your_webhook_secret_here', 'your_phone_number_id_here', 'your_business_account_id_here')
ON CONFLICT DO NOTHING;

-- Insert sample vendor for testing
INSERT INTO vendors (id, business_name, owner_name, phone, email, address, latitude, longitude, city, state, pincode, commission_rate) VALUES
('dev-vendor-123', 'CanCan Water Services', 'John Doe', '9876543210', 'john@cancan.com', '123 Main Street, Bangalore', 12.9716, 77.5946, 'Bangalore', 'Karnataka', '560001', 10.0)
ON CONFLICT (id) DO NOTHING;

-- Insert sample products for vendor
INSERT INTO vendor_products (vendor_id, product_id, price, stock_quantity) VALUES
('dev-vendor-123', (SELECT id FROM products WHERE name = '20L Mineral Water Can'), 35.00, 100),
('dev-vendor-123', (SELECT id FROM products WHERE name = '20L Packaged Drinking Water'), 30.00, 50),
('dev-vendor-123', (SELECT id FROM products WHERE name = '10L Mineral Water Can'), 25.00, 75)
ON CONFLICT (vendor_id, product_id) DO NOTHING;

-- ============================================
-- ROW LEVEL SECURITY (RLS) SETUP
-- ============================================

-- Enable RLS on all tables
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

-- Vendors can only access their own data
CREATE POLICY "Vendors can view own data" ON vendors
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Vendors can update own data" ON vendors
    FOR UPDATE USING (auth.uid() = user_id);

-- Customers can only be accessed by their vendor
CREATE POLICY "Vendors can view own customers" ON customers
    FOR ALL USING (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));

-- Orders can only be accessed by the vendor
CREATE POLICY "Vendors can view own orders" ON orders
    FOR ALL USING (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));

-- Order items follow order permissions
CREATE POLICY "Order items access via orders" ON order_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
            AND orders.vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid())
        )
    );

-- Vendor products permissions
CREATE POLICY "Vendors can manage own products" ON vendor_products
    FOR ALL USING (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));

-- Payment permissions
CREATE POLICY "Vendors can view own payments" ON payments
    FOR SELECT USING (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));

-- Wallet transaction permissions
CREATE POLICY "Vendors can view own wallet transactions" ON wallet_transactions
    FOR SELECT USING (vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()));

COMMIT;