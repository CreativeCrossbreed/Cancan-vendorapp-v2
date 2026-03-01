-- =====================================================
-- Can Can Vendor App - Database Setup (Fixed)
-- =====================================================
-- This script will handle existing tables properly
-- =====================================================

-- =====================================================
-- 1. DROP EXISTING TABLES (Fresh Start)
-- =====================================================
-- Warning: This will delete existing data!
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;
DROP TABLE IF EXISTS products CASCADE;

-- =====================================================
-- 2. CREATE ALL TABLES
-- =====================================================

-- Products table (create first as others reference it)
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vendors table
CREATE TABLE vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  business_name TEXT,
  address TEXT,
  is_active BOOLEAN DEFAULT true,
  is_on_vacation BOOLEAN DEFAULT false,
  max_daily_deliveries INTEGER DEFAULT 50,
  max_daily_cans INTEGER DEFAULT 100,
  working_hours JSONB DEFAULT '{"start": "08:00", "end": "20:00"}',
  working_days TEXT[] DEFAULT '{Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Customers table
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  flat_number TEXT,
  floor TEXT,
  building_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders table
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE NOT NULL,
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  delivery_date DATE NOT NULL,
  time_slot TEXT NOT NULL,
  total_amount NUMERIC(10, 2) DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')),
  is_delivered BOOLEAN DEFAULT false,
  delivered_at TIMESTAMP WITH TIME ZONE,
  payment_status TEXT DEFAULT 'unpaid' CHECK (payment_status IN ('paid', 'unpaid', 'pending')),
  payment_marked_at TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  cancellation_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Order items table
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10, 2) NOT NULL,
  subtotal NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Inventory table
CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  current_stock INTEGER DEFAULT 0 CHECK (current_stock >= 0),
  low_stock_threshold INTEGER DEFAULT 10 CHECK (low_stock_threshold >= 0),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(vendor_id, product_id)
);

-- =====================================================
-- 3. CREATE INDEXES
-- =====================================================

CREATE INDEX idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_delivery_date ON orders(delivery_date);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_inventory_vendor_id ON inventory(vendor_id);
CREATE INDEX idx_inventory_product_id ON inventory(product_id);
CREATE INDEX idx_vendors_phone ON vendors(phone);

-- =====================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- =====================================================

ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 5. CREATE RLS POLICIES
-- =====================================================

-- VENDORS
CREATE POLICY "Vendors can insert own profile" ON vendors
FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Vendors can view own profile" ON vendors
FOR SELECT TO authenticated USING (auth.uid() = id);

CREATE POLICY "Vendors can update own profile" ON vendors
FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Vendors cannot delete profiles" ON vendors
FOR DELETE TO authenticated USING (false);

-- ORDERS
CREATE POLICY "Vendors can view own orders" ON orders
FOR SELECT TO authenticated USING (auth.uid() = vendor_id);

CREATE POLICY "Vendors can insert own orders" ON orders
FOR INSERT TO authenticated WITH CHECK (auth.uid() = vendor_id);

CREATE POLICY "Vendors can update own orders" ON orders
FOR UPDATE TO authenticated USING (auth.uid() = vendor_id) WITH CHECK (auth.uid() = vendor_id);

CREATE POLICY "Vendors cannot delete orders" ON orders
FOR DELETE TO authenticated USING (false);

-- ORDER ITEMS
CREATE POLICY "Vendors can view own order items" ON order_items
FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.vendor_id = auth.uid())
);

CREATE POLICY "Vendors can insert own order items" ON order_items
FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.vendor_id = auth.uid())
);

-- CUSTOMERS
CREATE POLICY "Vendors can view relevant customers" ON customers
FOR SELECT TO authenticated USING (
  id IN (SELECT customer_id FROM orders WHERE vendor_id = auth.uid())
);

-- INVENTORY
CREATE POLICY "Vendors can view own inventory" ON inventory
FOR SELECT TO authenticated USING (auth.uid() = vendor_id);

CREATE POLICY "Vendors can insert own inventory" ON inventory
FOR INSERT TO authenticated WITH CHECK (auth.uid() = vendor_id);

CREATE POLICY "Vendors can update own inventory" ON inventory
FOR UPDATE TO authenticated USING (auth.uid() = vendor_id) WITH CHECK (auth.uid() = vendor_id);

CREATE POLICY "Vendors cannot delete inventory" ON inventory
FOR DELETE TO authenticated USING (false);

-- PRODUCTS
CREATE POLICY "Authenticated users can view products" ON products
FOR SELECT TO authenticated USING (is_active = true);

-- =====================================================
-- 6. CREATE HELPER FUNCTIONS
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. CREATE TRIGGERS
-- =====================================================

CREATE TRIGGER update_vendors_updated_at
BEFORE UPDATE ON vendors FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
BEFORE UPDATE ON orders FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at
BEFORE UPDATE ON customers FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON products FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 8. INSERT SAMPLE PRODUCTS
-- =====================================================

INSERT INTO products (name, price, description) VALUES
  ('20L Water Can', 30.00, 'Standard 20-liter water can'),
  ('10L Water Can', 20.00, 'Compact 10-liter water can'),
  ('5L Water Can', 15.00, 'Small 5-liter water can');

-- =====================================================
-- 9. GRANT PERMISSIONS
-- =====================================================

GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO authenticated;

-- =====================================================
-- COMPLETE!
-- =====================================================
