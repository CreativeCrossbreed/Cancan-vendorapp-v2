-- ============================================
-- UNIFIED SUPABASE DATABASE SCHEMA
-- Single source of truth for Mobile App + Admin Dashboard
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- AUTHENTICATION & USER MANAGEMENT
-- ============================================

-- Custom user profiles table that extends Supabase auth.users
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT email_length CHECK (char_length(email) <= 255),
  CONSTRAINT website_length CHECK (char_length(full_name) <= 500)
);

-- Set up Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- ============================================
-- ADMIN USER MANAGEMENT
-- ============================================

-- Admin users for dashboard access
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'admin' NOT NULL CHECK (role IN ('admin', 'super_admin', 'support')),
  is_active BOOLEAN DEFAULT true,
  last_login TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Admin sessions for dashboard authentication
CREATE TABLE IF NOT EXISTS admin_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_user_id UUID REFERENCES admin_users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- VENDOR MANAGEMENT (Admin Managed)
-- ============================================

-- Vendors table - Water can delivery vendors
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Basic Information
  business_name VARCHAR(255) NOT NULL,
  owner_name VARCHAR(255) NOT NULL,
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255),

  -- Address & Location (GEOCODED)
  address TEXT NOT NULL,
  flat_number VARCHAR(50),
  floor VARCHAR(20),
  building_name VARCHAR(255),
  landmark VARCHAR(255),
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  city VARCHAR(100),
  state VARCHAR(100),
  pincode VARCHAR(10),

  -- Business Details
  gst_number VARCHAR(50),
  fssai_license VARCHAR(100),
  pan_number VARCHAR(20),
  aadhaar_number VARCHAR(20),

  -- Service Areas (GEO-FENCED)
  service_radius_km INTEGER DEFAULT 5 DEFAULT 5,
  service_areas GEOMETRY(POLYGON, 4326)[], -- Array of service area polygons
  service_pincodes TEXT[], -- Array of serviceable pincodes

  -- Status Management
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected', 'suspended')),
  verification_documents TEXT[], -- Array of document URLs
  verification_notes TEXT,
  onboarding_status VARCHAR(20) DEFAULT 'pending' CHECK (onboarding_status IN ('pending', 'in_progress', 'completed', 'rejected')),

  -- Business Operations
  is_on_vacation BOOLEAN DEFAULT false,
  vacation_start_date TIMESTAMP WITH TIME ZONE,
  vacation_end_date TIMESTAMP WITH TIME ZONE,
  vacation_reason TEXT,
  auto_reply_enabled BOOLEAN DEFAULT true,
  vacation_message TEXT DEFAULT 'Currently on vacation. We will resume deliveries soon.',

  -- Business Hours (JSON)
  business_hours JSONB DEFAULT '{
    "monday": {"open": "09:00", "close": "21:00", "closed": false},
    "tuesday": {"open": "09:00", "close": "21:00", "closed": false},
    "wednesday": {"open": "09:00", "close": "21:00", "closed": false},
    "thursday": {"open": "09:00", "close": "21:00", "closed": false},
    "friday": {"open": "09:00", "close": "21:00", "closed": false},
    "saturday": {"open": "09:00", "close": "21:00", "closed": false},
    "sunday": {"open": "09:00", "close": "21:00", "closed": false}
  }',

  -- Performance Metrics (AUTO-CALCULATED)
  rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  total_reviews INTEGER DEFAULT 0,
  total_orders INTEGER DEFAULT 0,
  completed_orders INTEGER DEFAULT 0,
  cancelled_orders INTEGER DEFAULT 0,
  average_delivery_time INTEGER DEFAULT 30, -- in minutes
  total_revenue DECIMAL(12,2) DEFAULT 0.0,

  -- Financial Settings
  commission_rate DECIMAL(5,2) DEFAULT 10.0 CHECK (commission_rate >= 0 AND commission_rate <= 100),
  wallet_balance DECIMAL(10,2) DEFAULT 0.0,
  pending_commissions DECIMAL(10,2) DEFAULT 0.0,

  -- Inventory Settings
  inventory_alert_threshold INTEGER DEFAULT 10,
  accepts_cod BOOLEAN DEFAULT true,
  accepts_online_payment BOOLEAN DEFAULT true,

  -- System Fields
  created_by UUID REFERENCES admin_users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_location_update TIMESTAMP WITH TIME ZONE
);

-- Enable RLS for vendors
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;

-- Vendors policies
CREATE POLICY "Vendors can view own profile" ON vendors FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all vendors" ON vendors FOR SELECT USING (
  EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = true)
);
CREATE POLICY "Admins can insert vendors" ON vendors FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = true)
);
CREATE POLICY "Admins can update vendors" ON vendors FOR UPDATE USING (
  EXISTS (SELECT 1 FROM admin_users WHERE id = auth.uid() AND is_active = true)
);
CREATE POLICY "Vendors can update limited own fields" ON vendors FOR UPDATE USING (
  auth.uid() = user_id AND (
    -- Vendors can only update business operation fields
    jsonb_build_object(
      'is_on_vacation', NEW.is_on_vacation,
      'vacation_start_date', NEW.vacation_start_date,
      'vacation_end_date', NEW.vacation_end_date,
      'vacation_reason', NEW.vacation_reason,
      'auto_reply_enabled', NEW.auto_reply_enabled,
      'vacation_message', NEW.vacation_message,
      'business_hours', NEW.business_hours
    ) = jsonb_build_object(
      'is_on_vacation', OLD.is_on_vacation,
      'vacation_start_date', OLD.vacation_start_date,
      'vacation_end_date', OLD.vacation_end_date,
      'vacation_reason', OLD.vacation_reason,
      'auto_reply_enabled', OLD.auto_reply_enabled,
      'vacation_message', OLD.vacation_message,
      'business_hours', OLD.business_hours
    )
  )
);

-- ============================================
-- CUSTOMER MANAGEMENT
-- ============================================

CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  address TEXT,
  flat_number VARCHAR(50),
  floor VARCHAR(20),
  building_name VARCHAR(255),
  landmark VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  city VARCHAR(100),
  state VARCHAR(100),
  pincode VARCHAR(10),

  -- Customer Preferences
  preferred_delivery_time VARCHAR(50),
  special_instructions TEXT,
  is_verified BOOLEAN DEFAULT false,

  -- Customer Status
  is_active BOOLEAN DEFAULT true,
  verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'blocked')),

  -- Performance Metrics
  total_orders INTEGER DEFAULT 0,
  completed_orders INTEGER DEFAULT 0,
  cancelled_orders INTEGER DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0.0,
  average_order_value DECIMAL(10,2) DEFAULT 0.0,
  last_order_date TIMESTAMP WITH TIME ZONE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS for customers
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PRODUCT CATALOG
-- ============================================

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(100) NOT NULL,
  sku VARCHAR(100) UNIQUE,

  -- Product Details
  capacity_ml INTEGER DEFAULT 20000, -- 20 liter water can
  weight_grams INTEGER,
  dimensions JSONB,

  -- Product Images
  image_url TEXT,
  additional_images TEXT[],

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,

  -- System Fields
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- VENDOR PRODUCTS (PRICING & INVENTORY)
-- ============================================

CREATE TABLE IF NOT EXISTS vendor_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,

  -- Pricing
  selling_price DECIMAL(10,2) NOT NULL,
  deposit_amount DECIMAL(10,2) DEFAULT 0.0,
  mrp DECIMAL(10,2),

  -- Inventory
  current_stock INTEGER DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 10,
  reorder_quantity INTEGER DEFAULT 50,

  -- Status
  is_active BOOLEAN DEFAULT true,
  is_available BOOLEAN DEFAULT true,

  -- System Fields
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  UNIQUE(vendor_id, product_id)
);

-- ============================================
-- ORDER MANAGEMENT
-- ============================================

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Order Details
  order_number VARCHAR(50) UNIQUE NOT NULL,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,

  -- Order Items
  order_items JSONB NOT NULL, -- Array of order items with quantities and prices

  -- Delivery Information
  delivery_address JSONB NOT NULL,
  delivery_date DATE NOT NULL,
  delivery_time_slot VARCHAR(50),
  special_instructions TEXT,

  -- Order Status
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled')),
  payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),

  -- Financial Details
  subtotal DECIMAL(10,2) NOT NULL,
  delivery_fee DECIMAL(10,2) DEFAULT 0.0,
  tax_amount DECIMAL(10,2) DEFAULT 0.0,
  total_amount DECIMAL(10,2) NOT NULL,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  confirmed_at TIMESTAMP WITH TIME ZONE,
  prepared_at TIMESTAMP WITH TIME ZONE,
  out_for_delivery_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  cancelled_at TIMESTAMP WITH TIME ZONE,

  -- Cancellation Details
  cancellation_reason TEXT,
  cancelled_by UUID REFERENCES admin_users(id),

  -- Delivery Details
  delivery_partner_name VARCHAR(255),
  delivery_partner_phone VARCHAR(20),
  delivery_notes TEXT
);

-- Enable RLS for orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PAYMENT MANAGEMENT
-- ============================================

CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,

  -- Payment Details
  payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('cod', 'online', 'wallet')),
  transaction_id VARCHAR(255) UNIQUE,
  gateway_response JSONB,

  -- Payment Status
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded')),

  -- Amount
  amount DECIMAL(10,2) NOT NULL,
  commission_amount DECIMAL(10,2) DEFAULT 0.0,
  vendor_amount DECIMAL(10,2) DEFAULT 0.0,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  processed_at TIMESTAMP WITH TIME ZONE,

  -- Refund Details (if applicable)
  refund_amount DECIMAL(10,2) DEFAULT 0.0,
  refund_reason TEXT,
  refund_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- VENDOR WALLET
-- ============================================

CREATE TABLE IF NOT EXISTS vendor_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,

  -- Wallet Balance
  balance DECIMAL(10,2) DEFAULT 0.0,
  pending_balance DECIMAL(10,2) DEFAULT 0.0,

  -- System Fields
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  UNIQUE(vendor_id)
);

-- ============================================
-- WALLET TRANSACTIONS
-- ============================================

CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_wallet_id UUID REFERENCES vendor_wallets(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,

  -- Transaction Details
  type VARCHAR(20) NOT NULL CHECK (type IN ('credit', 'debit', 'commission', 'refund')),
  amount DECIMAL(10,2) NOT NULL,
  balance_after DECIMAL(10,2) NOT NULL,

  -- Related Information
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  description TEXT,
  reference_id VARCHAR(255),

  -- Status
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  processed_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- NOTIFICATIONS
-- ============================================

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('vendor', 'customer', 'admin')),
  recipient_id UUID NOT NULL,

  -- Notification Content
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) NOT NULL,
  data JSONB,

  -- Status
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,

  -- Channels
  push_sent BOOLEAN DEFAULT false,
  email_sent BOOLEAN DEFAULT false,
  sms_sent BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- VENDOR LOCATION TRACKING
-- ============================================

CREATE TABLE IF NOT EXISTS vendor_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,

  -- Location Data
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  accuracy DECIMAL(8,2),
  altitude DECIMAL(8,2),
  speed DECIMAL(8,2),
  heading DECIMAL(8,2),

  -- Metadata
  location_method VARCHAR(20) DEFAULT 'gps' CHECK (location_method IN ('gps', 'network', 'manual')),
  battery_level INTEGER,
  is_charging BOOLEAN DEFAULT false,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  -- Index for time-based queries
  INDEX(vendor_id, created_at)
);

-- ============================================
-- AUDIT LOGS
-- ============================================

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Action Details
  table_name VARCHAR(100) NOT NULL,
  record_id UUID NOT NULL,
  action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),

  -- User Details
  user_id UUID,
  user_type VARCHAR(20) CHECK (user_type IN ('admin', 'vendor', 'customer', 'system')),

  -- Change Details
  old_values JSONB,
  new_values JSONB,
  changed_fields TEXT[],

  -- Metadata
  ip_address INET,
  user_agent TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ============================================
-- SYSTEM SETTINGS
-- ============================================

CREATE TABLE IF NOT EXISTS system_settings (
  key VARCHAR(255) PRIMARY KEY,
  value JSONB NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT false,
  updated_by UUID REFERENCES admin_users(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert default system settings
INSERT INTO system_settings (key, value, description, is_public) VALUES
('business_commission_rate', '10.0', 'Default commission rate for new vendors', false),
('minimum_order_amount', '50.0', 'Minimum order amount', true),
('delivery_fee', '10.0', 'Standard delivery fee', true),
('vendor_verification_required', 'true', 'Require admin verification for new vendors', false),
('auto_assign_orders', 'true', 'Automatically assign orders to vendors', false)
ON CONFLICT (key) DO NOTHING;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Vendor indexes
CREATE INDEX IF NOT EXISTS idx_vendors_phone ON vendors(phone);
CREATE INDEX IF NOT EXISTS idx_vendors_location ON vendors USING GIST (ST_Point(longitude, latitude));
CREATE INDEX IF NOT EXISTS idx_vendors_status ON vendors(is_active, is_verified);
CREATE INDEX IF NOT EXISTS idx_vendors_created_by ON vendors(created_by);

-- Order indexes
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_vendor ON orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(delivery_date);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);

-- Payment indexes
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_vendor ON payments(vendor_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

-- Customer indexes
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_customers_location ON customers USING GIST (ST_Point(longitude, latitude));

-- Location tracking indexes
CREATE INDEX IF NOT EXISTS idx_vendor_locations_vendor ON vendor_locations(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_locations_created_at ON vendor_locations(created_at);

-- Notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_type, recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(recipient_type, recipient_id, is_read);

-- ============================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ============================================

-- Update vendor statistics
CREATE OR REPLACE FUNCTION update_vendor_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE vendors
        SET total_orders = total_orders + 1,
            updated_at = now()
        WHERE id = NEW.vendor_id;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != NEW.status THEN
            CASE
                WHEN NEW.status = 'delivered' THEN
                    UPDATE vendors
                    SET completed_orders = completed_orders + 1,
                        updated_at = now()
                    WHERE id = NEW.vendor_id;
                WHEN NEW.status = 'cancelled' THEN
                    UPDATE vendors
                    SET cancelled_orders = cancelled_orders + 1,
                        updated_at = now()
                    WHERE id = NEW.vendor_id;
            END CASE;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_vendor_stats_trigger
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_vendor_stats();

-- Update customer statistics
CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE customers
        SET total_orders = total_orders + 1,
            total_spent = total_spent + NEW.total_amount,
            last_order_date = NEW.created_at,
            updated_at = now()
        WHERE id = NEW.customer_id;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != NEW.status THEN
            CASE
                WHEN NEW.status = 'delivered' THEN
                    UPDATE customers
                    SET completed_orders = completed_orders + 1,
                        updated_at = now()
                    WHERE id = NEW.customer_id;
                WHEN NEW.status = 'cancelled' THEN
                    UPDATE customers
                    SET cancelled_orders = cancelled_orders + 1,
                        updated_at = now()
                    WHERE id = NEW.customer_id;
            END CASE;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_stats_trigger
    AFTER INSERT OR UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_customer_stats();

-- Update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply timestamp update triggers
CREATE TRIGGER update_vendors_updated_at BEFORE UPDATE ON vendors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- REAL-TIME SUBSCRIPTIONS
-- ============================================

-- Enable realtime for critical tables
ALTER TABLE orders REPLICA IDENTITY FULL;
ALTER TABLE vendors REPLICA IDENTITY FULL;
ALTER TABLE payments REPLICA IDENTITY FULL;
ALTER TABLE notifications REPLICA IDENTITY FULL;

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================

-- Insert sample admin user
INSERT INTO admin_users (email, password_hash, full_name, role) VALUES
('admin@cancan.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj3QJgusSuo6', 'System Administrator', 'super_admin')
ON CONFLICT (email) DO NOTHING;

-- Insert sample products
INSERT INTO products (name, description, category, sku, capacity_ml) VALUES
('20L Bisleri Water Can', 'Premium 20 liter Bisleri mineral water can', 'water_can', 'BISLERI-20L', 20000),
('20L Aquafina Water Can', '20 liter Aquafina purified drinking water can', 'water_can', 'AQUAFINA-20L', 20000),
('20L Kinley Water Can', '20 liter Kinley mineral water can', 'water_can', 'KINLEY-20L', 20000)
ON CONFLICT (sku) DO NOTHING;

-- ============================================
-- FUNCTIONS FOR BUSINESS LOGIC
-- ============================================

-- Find nearest vendors for a location
CREATE OR REPLACE FUNCTION find_nearest_vendors(
    p_latitude DECIMAL,
    p_longitude DECIMAL,
    p_radius_km INTEGER DEFAULT 10,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    vendor_id UUID,
    business_name VARCHAR(255),
    phone VARCHAR(20),
    distance_km DECIMAL,
    rating DECIMAL(3,2),
    delivery_time INTEGER,
    is_available BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        v.id,
        v.business_name,
        v.phone,
        ST_Distance(
            ST_Point(v.longitude, v.latitude)::geography,
            ST_Point(p_longitude, p_latitude)::geography
        ) / 1000 AS distance_km,
        v.rating,
        v.average_delivery_time,
        v.is_active AND NOT v.is_on_vacation AS is_available
    FROM vendors v
    WHERE v.is_active = true
    AND v.is_verified = true
    AND v.is_on_vacation = false
    AND ST_DWithin(
        ST_Point(v.longitude, v.latitude)::geography,
        ST_Point(p_longitude, p_latitude)::geography,
        p_radius_km * 1000
    )
    ORDER BY distance_km
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Calculate vendor commission for an order
CREATE OR REPLACE FUNCTION calculate_vendor_commission(
    p_order_id UUID
)
RETURNS DECIMAL AS $$
DECLARE
    vendor_commission_rate DECIMAL;
    order_amount DECIMAL;
    commission_amount DECIMAL;
BEGIN
    -- Get vendor's commission rate and order amount
    SELECT v.commission_rate, o.total_amount
    INTO vendor_commission_rate, order_amount
    FROM vendors v
    JOIN orders o ON o.vendor_id = v.id
    WHERE o.id = p_order_id;

    -- Calculate commission (order_amount * commission_rate / 100)
    commission_amount := order_amount * vendor_commission_rate / 100;

    RETURN commission_amount;
END;
$$ LANGUAGE plpgsql;

-- Check if customer is in vendor's service area
CREATE OR REPLACE FUNCTION is_in_service_area(
    p_vendor_id UUID,
    p_customer_lat DECIMAL,
    p_customer_lng DECIMAL
)
RETURNS BOOLEAN AS $$
DECLARE
    customer_point GEOMETRY;
    service_areas GEOMETRY[];
    i INTEGER;
BEGIN
    -- Create customer location point
    customer_point := ST_Point(p_customer_lng, p_customer_lat);

    -- Get vendor's service areas
    SELECT ARRAY(SELECT service_area FROM vendors WHERE id = p_vendor_id)
    INTO service_areas;

    -- Check if customer point is in any service area
    IF service_areas IS NOT NULL THEN
        FOR i IN 1..array_length(service_areas, 1) LOOP
            IF ST_Contains(service_areas[i], customer_point) THEN
                RETURN true;
            END IF;
        END LOOP;
    END IF;

    -- If no service areas defined, check by radius
    RETURN EXISTS (
        SELECT 1 FROM vendors
        WHERE id = p_vendor_id
        AND ST_DWithin(
            ST_Point(longitude, latitude)::geography,
            customer_point::geography,
            service_radius_km * 1000
        )
    );
END;
$$ LANGUAGE plpgsql;