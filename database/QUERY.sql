-- =====================================================
-- CAN CAN VENDOR - DATABASE SETUP SCRIPT
-- Version: 2.0
-- Database: Supabase (PostgreSQL 15+)
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- HELPER FUNCTION: Update updated_at timestamp
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 1. VENDORS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    business_name TEXT NOT NULL,
    address TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_on_vacation BOOLEAN NOT NULL DEFAULT false,
    max_daily_deliveries INTEGER,
    max_daily_cans INTEGER,
    working_hours JSONB,
    working_days TEXT[],
    vacation_start_date TIMESTAMPTZ,
    vacation_end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS vendors_phone_idx ON vendors(phone);
CREATE INDEX IF NOT EXISTS vendors_is_active_idx ON vendors(is_active);
CREATE INDEX IF NOT EXISTS vendors_is_on_vacation_idx ON vendors(is_on_vacation);

CREATE TRIGGER update_vendors_updated_at
    BEFORE UPDATE ON vendors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 2. CUSTOMERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT NOT NULL,
    flat_number TEXT,
    floor TEXT,
    building_name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS customers_phone_idx ON customers(phone);
CREATE INDEX IF NOT EXISTS customers_name_idx ON customers(name);

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 3. PRODUCTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS products_name_idx ON products(name);
CREATE INDEX IF NOT EXISTS products_is_active_idx ON products(is_active);

-- =====================================================
-- 4. VENDOR_PRODUCTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS vendor_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    selling_price NUMERIC(10,2) NOT NULL,
    deposit_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    current_stock INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(vendor_id, product_id)
);

CREATE INDEX IF NOT EXISTS vendor_products_vendor_product_idx ON vendor_products(vendor_id, product_id);
CREATE INDEX IF NOT EXISTS vendor_products_vendor_idx ON vendor_products(vendor_id);
CREATE INDEX IF NOT EXISTS vendor_products_current_stock_idx ON vendor_products(current_stock);

CREATE TRIGGER update_vendor_products_updated_at
    BEFORE UPDATE ON vendor_products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. ORDERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT UNIQUE NOT NULL,
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    delivery_date DATE NOT NULL,
    time_slot TEXT NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('pending', 'completed', 'cancelled')),
    is_delivered BOOLEAN NOT NULL DEFAULT false,
    delivered_at TIMESTAMPTZ,
    payment_status TEXT NOT NULL CHECK(payment_status IN ('paid', 'unpaid', 'partial')) DEFAULT 'unpaid',
    amount_paid NUMERIC(10,2) NOT NULL DEFAULT 0,
    remaining_amount NUMERIC(10,2) NOT NULL,
    payment_marked_at TIMESTAMPTZ,
    notes TEXT,
    cancellation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS orders_vendor_date_status_idx ON orders(vendor_id, delivery_date, status);
CREATE INDEX IF NOT EXISTS orders_customer_idx ON orders(customer_id);
CREATE INDEX IF NOT EXISTS orders_order_number_idx ON orders(order_number);
CREATE INDEX IF NOT EXISTS orders_status_idx ON orders(status);
CREATE INDEX IF NOT EXISTS orders_delivery_date_idx ON orders(delivery_date);
CREATE INDEX IF NOT EXISTS orders_payment_status_idx ON orders(payment_status);

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION calculate_remaining_amount()
RETURNS TRIGGER AS $$
BEGIN
    NEW.remaining_amount = NEW.total_amount - NEW.amount_paid;

    IF NEW.amount_paid >= NEW.total_amount THEN
        NEW.payment_status = 'paid';
    ELSIF NEW.amount_paid > 0 THEN
        NEW.payment_status = 'partial';
    ELSE
        NEW.payment_status = 'unpaid';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_orders_remaining_amount
    BEFORE INSERT OR UPDATE OF total_amount, amount_paid ON orders
    FOR EACH ROW
    EXECUTE FUNCTION calculate_remaining_amount();

-- =====================================================
-- 6. ORDER_ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK(quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(10,2) NOT NULL
);

CREATE INDEX IF NOT EXISTS order_items_order_idx ON order_items(order_id);
CREATE INDEX IF NOT EXISTS order_items_product_idx ON order_items(product_id);

-- =====================================================
-- 7. PAYMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK(amount > 0),
    payment_method TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS payments_order_idx ON payments(order_id);
CREATE INDEX IF NOT EXISTS payments_created_at_idx ON payments(created_at);

CREATE OR REPLACE FUNCTION update_order_payment_on_payment_insert()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders
    SET amount_paid = amount_paid + NEW.amount,
        payment_marked_at = CASE
            WHEN (amount_paid + NEW.amount) >= total_amount THEN NOW()
            ELSE payment_marked_at
        END
    WHERE id = NEW.order_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_on_payment_insert
    AFTER INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_order_payment_on_payment_insert();

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

CREATE OR REPLACE VIEW orders_full AS
SELECT
    o.*,
    c.name as customer_name,
    c.phone as customer_phone,
    c.address as customer_address,
    c.flat_number as customer_flat,
    c.floor as customer_floor,
    c.building_name as customer_building,
    jsonb_agg(
        jsonb_build_object(
            'id', oi.id,
            'product_id', oi.product_id,
            'product_name', p.name,
            'quantity', oi.quantity,
            'unit_price', oi.unit_price,
            'subtotal', oi.subtotal
        )
    ) FILTER (WHERE oi.id IS NOT NULL) as items
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.id
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.id
GROUP BY o.id, c.name, c.phone, c.address, c.flat_number, c.floor, c.building_name;

CREATE OR REPLACE VIEW vendor_inventory_status AS
SELECT
    vp.vendor_id,
    vp.product_id,
    p.name as product_name,
    vp.selling_price,
    vp.deposit_amount,
    vp.current_stock,
    vp.low_stock_threshold,
    CASE
        WHEN vp.current_stock = 0 THEN 'out_of_stock'
        WHEN vp.current_stock <= vp.low_stock_threshold THEN 'low_stock'
        ELSE 'in_stock'
    END as stock_status
FROM vendor_products vp
JOIN products p ON vp.product_id = p.id
WHERE p.is_active = true;

CREATE OR REPLACE VIEW order_payments_summary AS
SELECT
    o.id as order_id,
    o.order_number,
    o.total_amount,
    o.amount_paid,
    o.remaining_amount,
    o.payment_status,
    COALESCE(SUM(p.amount), 0) as total_payments,
    COUNT(p.id) as payment_count,
    jsonb_agg(
        jsonb_build_object(
            'id', p.id,
            'amount', p.amount,
            'payment_method', p.payment_method,
            'notes', p.notes,
            'created_at', p.created_at
        )
    ) FILTER (WHERE p.id IS NOT NULL) as payment_history
FROM orders o
LEFT JOIN payments p ON o.id = p.order_id
GROUP BY o.id, o.order_number, o.total_amount, o.amount_paid, o.remaining_amount, o.payment_status;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
    last_number TEXT;
    next_number INTEGER;
BEGIN
    SELECT order_number INTO last_number
    FROM orders
    ORDER BY created_at DESC
    LIMIT 1;

    IF last_number IS NULL THEN
        next_number := 1000;
    ELSE
        next_number := CAST(ltrim(last_number, '#') AS INTEGER) + 1;
    END IF;

    RETURN '#' || next_number;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own vendor profile" ON vendors
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can insert own vendor profile" ON vendors
    FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own vendor profile" ON vendors
    FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Vendors can view customers" ON customers
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.customer_id = customers.id
            AND orders.vendor_id = auth.uid()
        )
    );

CREATE POLICY "Authenticated users can view products" ON products
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Vendors can view own products" ON vendor_products
    FOR SELECT USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can insert own products" ON vendor_products
    FOR INSERT WITH CHECK (vendor_id = auth.uid());

CREATE POLICY "Vendors can update own products" ON vendor_products
    FOR UPDATE USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can delete own products" ON vendor_products
    FOR DELETE USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can view own orders" ON orders
    FOR SELECT USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can insert own orders" ON orders
    FOR INSERT WITH CHECK (vendor_id = auth.uid());

CREATE POLICY "Vendors can update own orders" ON orders
    FOR UPDATE USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can view order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
            AND orders.vendor_id = auth.uid()
        )
    );

CREATE POLICY "Vendors can insert order items" ON order_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = order_items.order_id
            AND orders.vendor_id = auth.uid()
        )
    );

CREATE POLICY "Vendors can view payments" ON payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = payments.order_id
            AND orders.vendor_id = auth.uid()
        )
    );

CREATE POLICY "Vendors can insert payments" ON payments
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.id = payments.order_id
            AND orders.vendor_id = auth.uid()
        )
    );

-- =====================================================
-- SEED DATA (OPTIONAL)
-- =====================================================

INSERT INTO products (name, is_active) VALUES
    ('20L Water Can', true),
    ('10L Water Can', true),
    ('5L Water Can', true)
ON CONFLICT DO NOTHING;
