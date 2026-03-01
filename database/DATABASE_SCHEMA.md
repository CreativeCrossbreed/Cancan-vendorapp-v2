# Can Can Vendor - Database Schema Documentation

## Overview

This document provides a comprehensive database schema for the Can Can Vendor application, a water can delivery management system built on Supabase (PostgreSQL).

**Database Technology**: Supabase (PostgreSQL 15+)
**Schema Version**: 2.0 (Fixed)
**Last Updated**: 2025-01-10

---

## Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     vendors     │       │     orders      │       │   customers     │
├─────────────────┤       ├─────────────────┤       ├─────────────────┤
│ id (PK)         │───┐   │ id (PK)         │───┐   │ id (PK)         │
│ phone           │   │   │ order_number    │   │   │ name            │
│ name            │   │   │ vendor_id (FK)  │───┘   │ phone           │
│ business_name   │   │   │ customer_id(FK) │─────→│ address         │
│ address         │   │   │ delivery_date   │       │ flat_number     │
│ is_active       │   │   │ time_slot       │       │ floor           │
│ is_on_vacation  │   │   │ total_amount    │       │ building_name   │
│ max_daily_*     │   │   │ status          │       │ created_at      │
│ working_hours   │   │   │ is_delivered    │       │ updated_at      │
│ working_days    │   │   │ payment_status  │       └─────────────────┘
│ vacation_*      │   │   │ amount_paid     │
│ created_at      │   │   │ remaining_amt   │
│ updated_at      │   │   │ notes           │
└─────────────────┘   │   │ cancellation_   │
                      │   │ created_at      │
                      │   │ updated_at      │
                      │   │ delivered_at    │
                      │   │ payment_marked_ │
                      │   └─────────────────┘
                      │
                      │       ┌─────────────────┐
                      │       │  order_items    │
                      │       ├─────────────────┤
                      └──────→│ id (PK)         │
                              │ order_id (FK)   │
                              │ product_id (FK) │
                              │ quantity        │
                              │ unit_price      │
                              │ subtotal        │
                              └─────────────────┘
                                      │
                                      │       ┌─────────────────┐
                                      │       │    products     │
                                      │       ├─────────────────┤
                                      └──────→│ id (PK)         │
                                              │ name            │
                                              │ is_active       │
                                              │ created_at      │
                                              └─────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      vendor_products                             │
├─────────────────────────────────────────────────────────────────┤
│ id (PK)                                                         │
│ vendor_id (FK) ─────────────────────────────────────────────┐   │
│ product_id (FK) ──────────────────────────────────────────┐ │   │
│ selling_price                                              │ │   │
│ deposit_amount                                             │ │   │
│ current_stock                                              │ │   │
│ low_stock_threshold                                       │ │   │
│ created_at                                                │ │   │
│ updated_at                                                │ │   │
└────────────────────────────────────────────────────────────┼───┼───┘
                                                             │   │
                      ┌──────────────────────────────────────┘   │
                      │                                          │
                      ↓                                          ↓
              ┌─────────────┐                          ┌─────────────┐
              │   vendors   │                          │  products   │
              └─────────────┘                          └─────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         payments                                 │
├─────────────────────────────────────────────────────────────────┤
│ id (PK)                                                         │
│ order_id (FK) ────────────────────────────────────────────────┐ │
│ amount                                                         │ │
│ payment_method                                                 │ │
│ notes                                                          │ │
│ created_at                                                    │ │
└─────────────────────────────────────────────────────────────────┘
                                                                    │
                                                                    ↓
                                                          ┌─────────────┐
                                                          │   orders    │
                                                          └─────────────┘
```

---

## Table Definitions

### 1. vendors

Stores vendor profile information and business settings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique vendor identifier (links to Supabase Auth) |
| phone | TEXT | UNIQUE, NOT NULL | Vendor phone number with +91 prefix |
| name | TEXT | NOT NULL | Vendor's personal name |
| business_name | TEXT | NOT NULL | Business/trade name |
| address | TEXT | NOT NULL | Business address |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | Account active status |
| is_on_vacation | BOOLEAN | NOT NULL, DEFAULT false | Vacation mode status |
| max_daily_deliveries | INTEGER | | Maximum deliveries per day |
| max_daily_cans | INTEGER | | Maximum cans to deliver per day |
| working_hours | JSONB | | Working hours configuration (flexible format) |
| working_days | TEXT[] | | Array of working days (e.g., ['mon', 'tue']) |
| vacation_start_date | TIMESTAMPTZ | | Vacation start date/time |
| vacation_end_date | TIMESTAMPTZ | | Vacation end date/time |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `vendors_phone_idx` ON phone (unique)
- `vendors_is_active_idx` ON is_active
- `vendors_is_on_vacation_idx` ON is_on_vacation

**working_hours JSONB Structure (Flexible - supports both formats):**

**Format 1 (Simple - matches app):**
```json
{
  "open": "09:00",
  "close": "18:00"
}
```

**Format 2 (Per-day - more flexible):**
```json
{
  "monday": { "start": "08:00", "end": "20:00", "enabled": true },
  "tuesday": { "start": "08:00", "end": "20:00", "enabled": true },
  "wednesday": { "start": "08:00", "end": "20:00", "enabled": true },
  "thursday": { "start": "08:00", "end": "20:00", "enabled": true },
  "friday": { "start": "08:00", "end": "20:00", "enabled": true },
  "saturday": { "start": "08:00", "end": "20:00", "enabled": true },
  "sunday": { "start": "08:00", "end": "14:00", "enabled": false }
}
```

---

### 2. customers

Customer information for delivery addresses.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Unique customer identifier |
| name | TEXT | NOT NULL | Customer's name |
| phone | TEXT | NOT NULL | Customer's phone number |
| address | TEXT | NOT NULL | Street address |
| flat_number | TEXT | | Flat/apartment number |
| floor | TEXT | | Floor number |
| building_name | TEXT | | Building/society name |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `customers_phone_idx` ON phone
- `customers_name_idx` ON name (for search)

**Note:** Phone numbers are not unique to allow same customer placing multiple orders with different vendors.

---

### 3. products

Master product catalog (types of water cans).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique product identifier |
| name | TEXT | NOT NULL | Product name (e.g., "20L Water Can") |
| is_active | BOOLEAN | NOT NULL, DEFAULT true | Product availability status |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |

**Indexes:**
- `products_name_idx` ON name
- `products_is_active_idx` ON is_active

**Notes:**
- This is a master catalog table
- Product names should be standardized across all vendors
- Vendors link to products via `vendor_products` table with their own pricing

---

### 4. vendor_products

Links products to vendors with vendor-specific pricing and inventory.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique relationship identifier |
| vendor_id | UUID | NOT NULL, FOREIGN KEY → vendors(id) | Vendor reference |
| product_id | UUID | NOT NULL, FOREIGN KEY → products(id) | Product reference |
| selling_price | NUMERIC(10,2) | NOT NULL | Selling price per unit |
| deposit_amount | NUMERIC(10,2) | NOT NULL, DEFAULT 0 | Refundable deposit amount |
| current_stock | INTEGER | NOT NULL, DEFAULT 0 | Current stock level |
| low_stock_threshold | INTEGER | NOT NULL, DEFAULT 10 | Alert threshold |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Record creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `vendor_products_vendor_product_idx` ON vendor_id, product_id (unique)
- `vendor_products_vendor_idx` ON vendor_id
- `vendor_products_current_stock_idx` ON current_stock

**Constraints:**
- UNIQUE(vendor_id, product_id) - One entry per vendor-product combination

**Business Logic:**
- Stock is automatically deducted when orders are marked as delivered
- Low stock alerts triggered when current_stock <= low_stock_threshold
- Vendors can set their own pricing for the same product

---

### 5. orders

Order headers with delivery and status information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique order identifier |
| order_number | TEXT | UNIQUE, NOT NULL | Human-readable order number (e.g., #1001) |
| vendor_id | UUID | NOT NULL, FOREIGN KEY → vendors(id) | Assigned vendor |
| customer_id | UUID | NOT NULL, FOREIGN KEY → customers(id) | Customer reference |
| delivery_date | DATE | NOT NULL | Scheduled delivery date |
| time_slot | TEXT | NOT NULL | Delivery time slot (e.g., "8:00 AM - 10:00 AM") |
| total_amount | NUMERIC(10,2) | NOT NULL | Total order value |
| status | TEXT | NOT NULL, CHECK(status IN ('pending','completed','cancelled')) | Order status |
| is_delivered | BOOLEAN | NOT NULL, DEFAULT false | Delivery confirmation |
| delivered_at | TIMESTAMPTZ | | Actual delivery timestamp |
| payment_status | TEXT | NOT NULL, CHECK(payment_status IN ('paid','unpaid','partial')) | Payment status |
| amount_paid | NUMERIC(10,2) | NOT NULL, DEFAULT 0 | Total amount paid (for partial payments) |
| remaining_amount | NUMERIC(10,2) | NOT NULL | Remaining amount to be paid |
| payment_marked_at | TIMESTAMPTZ | | Payment confirmation timestamp |
| notes | TEXT | | Delivery notes from customer |
| cancellation_reason | TEXT | | Reason for cancellation |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Order creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `orders_vendor_date_status_idx` ON vendor_id, delivery_date, status
- `orders_customer_idx` ON customer_id
- `orders_order_number_idx` ON order_number (unique)
- `orders_status_idx` ON status
- `orders_delivery_date_idx` ON delivery_date
- `orders_payment_status_idx` ON payment_status

**Common time_slots:**
- "6:00 AM - 8:00 AM"
- "8:00 AM - 10:00 AM"
- "10:00 AM - 12:00 PM"
- "4:00 PM - 6:00 PM"
- "6:00 PM - 8:00 PM"

**Business Logic:**
- `remaining_amount` = `total_amount` - `amount_paid`
- When `amount_paid` >= `total_amount`, `payment_status` should be 'paid'
- When `amount_paid` > 0 and < `total_amount`, `payment_status` should be 'partial'
- When `amount_paid` = 0, `payment_status` should be 'unpaid'

---

### 6. order_items

Line items for each order (products and quantities).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique line item identifier |
| order_id | UUID | NOT NULL, FOREIGN KEY → orders(id) ON DELETE CASCADE | Order reference |
| product_id | UUID | NOT NULL, FOREIGN KEY → products(id) | Product reference |
| quantity | INTEGER | NOT NULL, CHECK(quantity > 0) | Quantity ordered |
| unit_price | NUMERIC(10,2) | NOT NULL | Price per unit at order time |
| subtotal | NUMERIC(10,2) | NOT NULL | Line item total (quantity × unit_price) |

**Indexes:**
- `order_items_order_idx` ON order_id
- `order_items_product_idx` ON product_id

**Business Logic:**
- unit_price is captured at order time (historical pricing)
- Subtotal should equal quantity × unit_price
- When order status → completed, stock is deducted from vendor_products

---

### 7. payments

Payment transactions for orders (supports partial payments).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | Unique payment identifier |
| order_id | UUID | NOT NULL, FOREIGN KEY → orders(id) ON DELETE CASCADE | Order reference |
| amount | NUMERIC(10,2) | NOT NULL, CHECK(amount > 0) | Payment amount |
| payment_method | TEXT | | Payment method (e.g., 'cash', 'upi', 'card') |
| notes | TEXT | | Payment notes |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Payment timestamp |

**Indexes:**
- `payments_order_idx` ON order_id
- `payments_created_at_idx` ON created_at

**Business Logic:**
- Each payment record represents a single payment transaction
- Multiple payments can be made for the same order (partial payments)
- Sum of all payments for an order should not exceed `orders.total_amount`

---

## SQL Creation Script (Version 2.0 - Fixed)

```sql
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

-- Indexes
CREATE INDEX IF NOT EXISTS vendors_phone_idx ON vendors(phone);
CREATE INDEX IF NOT EXISTS vendors_is_active_idx ON vendors(is_active);
CREATE INDEX IF NOT EXISTS vendors_is_on_vacation_idx ON vendors(is_on_vacation);

-- Updated at trigger
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

-- Updated at trigger
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

-- Updated at trigger
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

-- Updated at trigger
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to calculate remaining_amount
CREATE OR REPLACE FUNCTION calculate_remaining_amount()
RETURNS TRIGGER AS $$
BEGIN
    NEW.remaining_amount = NEW.total_amount - NEW.amount_paid;
    
    -- Update payment_status based on amount_paid
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

-- Trigger to update order amount_paid when payment is inserted
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

-- View: Orders with customer and items
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

-- View: Vendor inventory status
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

-- View: Order payments summary
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

-- Function: Generate order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
    last_number TEXT;
    next_number INTEGER;
BEGIN
    -- Get last order number or start at 1000
    SELECT order_number INTO last_number
    FROM orders
    ORDER BY created_at DESC
    LIMIT 1;

    IF last_number IS NULL THEN
        next_number := 1000;
    ELSE
        -- Extract number from #1234 format
        next_number := CAST(ltrim(last_number, '#') AS INTEGER) + 1;
    END IF;

    RETURN '#' || next_number;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Vendors: Only access own record
CREATE POLICY "Users can view own vendor profile" ON vendors
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can insert own vendor profile" ON vendors
    FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY "Users can update own vendor profile" ON vendors
    FOR UPDATE USING (id = auth.uid());

-- Customers: Vendors can view all customers in their orders
CREATE POLICY "Vendors can view customers" ON customers
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders
            WHERE orders.customer_id = customers.id
            AND orders.vendor_id = auth.uid()
        )
    );

-- Products: Read-only for authenticated users
CREATE POLICY "Authenticated users can view products" ON products
    FOR SELECT USING (auth.role() = 'authenticated');

-- Vendor Products: Vendors can only access own products
CREATE POLICY "Vendors can view own products" ON vendor_products
    FOR SELECT USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can insert own products" ON vendor_products
    FOR INSERT WITH CHECK (vendor_id = auth.uid());

CREATE POLICY "Vendors can update own products" ON vendor_products
    FOR UPDATE USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can delete own products" ON vendor_products
    FOR DELETE USING (vendor_id = auth.uid());

-- Orders: Vendors can only access own orders
CREATE POLICY "Vendors can view own orders" ON orders
    FOR SELECT USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can insert own orders" ON orders
    FOR INSERT WITH CHECK (vendor_id = auth.uid());

CREATE POLICY "Vendors can update own orders" ON orders
    FOR UPDATE USING (vendor_id = auth.uid());

-- Order Items: Accessible via orders
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

-- Payments: Accessible via orders
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

-- Insert sample products
INSERT INTO products (name, is_active) VALUES
    ('20L Water Can', true),
    ('10L Water Can', true),
    ('5L Water Can', true)
ON CONFLICT DO NOTHING;
```

---

## Migration Scripts

### Migration 1: From Version 1.0 to 2.0

**Run this migration if you have an existing database with version 1.0 schema.**

```sql
-- =====================================================
-- MIGRATION 1: v1.0 → v2.0
-- =====================================================

BEGIN;

-- 1. Add created_at and updated_at to customers table
ALTER TABLE customers
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Create trigger for customers updated_at
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 2. Add updated_at to vendor_products table
ALTER TABLE vendor_products
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Create trigger for vendor_products updated_at
CREATE TRIGGER update_vendor_products_updated_at
    BEFORE UPDATE ON vendor_products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 3. Add updated_at to orders table
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Create trigger for orders updated_at
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 4. Add partial payment support to orders table
ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS amount_paid NUMERIC(10,2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS remaining_amount NUMERIC(10,2) NOT NULL DEFAULT 0;

-- Update payment_status check constraint to include 'partial'
ALTER TABLE orders
    DROP CONSTRAINT IF EXISTS orders_payment_status_check;

ALTER TABLE orders
    ADD CONSTRAINT orders_payment_status_check 
    CHECK (payment_status IN ('paid', 'unpaid', 'partial'));

-- Calculate initial remaining_amount for existing orders
UPDATE orders
SET remaining_amount = total_amount - amount_paid;

-- Create trigger to auto-calculate remaining_amount
CREATE OR REPLACE FUNCTION calculate_remaining_amount()
RETURNS TRIGGER AS $$
BEGIN
    NEW.remaining_amount = NEW.total_amount - NEW.amount_paid;
    
    -- Update payment_status based on amount_paid
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

-- 5. Create payments table
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

-- Create trigger to update order amount_paid when payment is inserted
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

-- 6. Add index for payment_status
CREATE INDEX IF NOT EXISTS orders_payment_status_idx ON orders(payment_status);

-- 7. Enable RLS on payments table
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for payments
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

-- 8. Update orders_full view to handle NULL items
DROP VIEW IF EXISTS orders_full;
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

-- 9. Create order_payments_summary view
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

COMMIT;
```

### Migration 2: Backfill existing payment data (Optional)

**If you have existing orders with payment_status = 'paid', backfill the payments table:**

```sql
-- =====================================================
-- MIGRATION 2: Backfill payments from existing orders
-- =====================================================

BEGIN;

-- Insert payment records for orders that are marked as paid
INSERT INTO payments (order_id, amount, payment_method, notes, created_at)
SELECT 
    id as order_id,
    total_amount as amount,
    'cash' as payment_method,  -- Default method, update if you have actual data
    'Migrated from existing order' as notes,
    COALESCE(payment_marked_at, created_at) as created_at
FROM orders
WHERE payment_status = 'paid'
  AND amount_paid = 0  -- Only backfill if amount_paid hasn't been set
ON CONFLICT DO NOTHING;

-- Update amount_paid for orders that are marked as paid
UPDATE orders
SET amount_paid = total_amount,
    remaining_amount = 0
WHERE payment_status = 'paid'
  AND amount_paid = 0;

COMMIT;
```

---

## Database Operations Reference

### Common Query Patterns

#### 1. Get Today's Orders by Status

```sql
SELECT
    o.*,
    c.name as customer_name,
    c.phone as customer_phone,
    c.address as customer_address,
    c.flat_number,
    c.floor,
    c.building_name
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.vendor_id = $1
  AND o.delivery_date = CURRENT_DATE
  AND o.status = 'pending'
ORDER BY o.time_slot;
```

#### 2. Get Order with Items

```sql
SELECT
    o.*,
    jsonb_build_object(
        'id', c.id,
        'name', c.name,
        'phone', c.phone,
        'address', c.address,
        'flat_number', c.flat_number,
        'floor', c.floor,
        'building_name', c.building_name
    ) as customer,
    jsonb_agg(
        jsonb_build_object(
            'id', oi.id,
            'quantity', oi.quantity,
            'unit_price', oi.unit_price,
            'subtotal', oi.subtotal,
            'product', jsonb_build_object(
                'id', p.id,
                'name', p.name
            )
        )
    ) as items
FROM orders o
JOIN customers c ON o.customer_id = c.id
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.id
WHERE o.id = $1
GROUP BY o.id, c.id;
```

#### 3. Get Vendor Products with Stock Status

```sql
SELECT
    vp.id,
    vp.selling_price,
    vp.deposit_amount,
    vp.current_stock,
    vp.low_stock_threshold,
    p.id as product_id,
    p.name as product_name,
    CASE
        WHEN vp.current_stock = 0 THEN 'out_of_stock'
        WHEN vp.current_stock <= vp.low_stock_threshold THEN 'low_stock'
        ELSE 'in_stock'
    END as stock_status
FROM vendor_products vp
JOIN products p ON vp.product_id = p.id
WHERE vp.vendor_id = $1
  AND p.is_active = true
ORDER BY
    CASE
        WHEN vp.current_stock = 0 THEN 1
        WHEN vp.current_stock <= vp.low_stock_threshold THEN 2
        ELSE 3
    END,
    p.name;
```

#### 4. Record a Payment (Partial or Full)

```sql
-- Insert payment record
INSERT INTO payments (order_id, amount, payment_method, notes)
VALUES ($1, $2, $3, $4);

-- The trigger will automatically update orders.amount_paid and payment_status
```

#### 5. Get Order Payment History

```sql
SELECT
    o.order_number,
    o.total_amount,
    o.amount_paid,
    o.remaining_amount,
    o.payment_status,
    jsonb_agg(
        jsonb_build_object(
            'amount', p.amount,
            'payment_method', p.payment_method,
            'created_at', p.created_at
        )
        ORDER BY p.created_at
    ) as payment_history
FROM orders o
LEFT JOIN payments p ON o.id = p.order_id
WHERE o.id = $1
GROUP BY o.id, o.order_number, o.total_amount, o.amount_paid, o.remaining_amount, o.payment_status;
```

#### 6. Deduct Stock on Order Delivery

```sql
-- Update order status
UPDATE orders
SET
    status = 'completed',
    is_delivered = true,
    delivered_at = NOW()
WHERE id = $1;

-- Deduct stock for each order item
UPDATE vendor_products vp
SET current_stock = current_stock - oi.quantity
FROM order_items oi
WHERE oi.order_id = $1
  AND vp.vendor_id = (SELECT vendor_id FROM orders WHERE id = $1)
  AND vp.product_id = oi.product_id;
```

#### 7. Get Daily Summary

```sql
SELECT
    COUNT(DISTINCT o.id) as total_orders,
    SUM(oi.quantity) as total_cans,
    SUM(o.total_amount) as total_earnings,
    SUM(o.amount_paid) as total_collected,
    SUM(o.remaining_amount) as total_pending
FROM orders o
JOIN order_items oi ON o.id = oi.order_id
WHERE o.vendor_id = $1
  AND o.delivery_date = CURRENT_DATE
  AND o.status = 'pending';
```

---

## Feature-to-Table Mapping

| App Feature | Tables Used | Description |
|-------------|-------------|-------------|
| **Authentication** | `vendors` (via Supabase Auth) | Vendor profile linked to auth.user.id |
| **Profile Setup** | `vendors` | Create/update vendor business information |
| **Home Dashboard** | `orders`, `customers`, `order_items` | Today's pending/completed orders |
| **Order History** | `orders`, `customers`, `order_items` | Past orders by date range |
| **Order Details** | `orders`, `customers`, `order_items`, `products` | Full order with customer info |
| **Order Status** | `orders` | Update delivery/payment status |
| **Inventory Management** | `vendor_products`, `products` | Stock levels and product catalog |
| **Add Product** | `products`, `vendor_products` | Create product and link to vendor |
| **Update Stock** | `vendor_products` | Add/remove inventory |
| **Product Catalog** | `vendor_products`, `products` | Vendor's product list with pricing |
| **Payments** | `orders`, `payments` | Track payment status and history |
| **Partial Payments** | `payments`, `orders` | Record multiple payments per order |
| **Vacation Mode** | `vendors` | Toggle vacation dates |
| **Settings** | `vendors` | Business hours, delivery limits |
| **QR Code** | `vendors`, `orders` | Share vendor profile/orders |

---

## Data Integrity Rules

### 1. Cascading Deletes
- **vendor_products**: CASCADE when vendor or product deleted
- **order_items**: CASCADE when order deleted
- **payments**: CASCADE when order deleted
- **orders**: CASCADE when vendor deleted, RESTRICT for customer
- **customers**: RESTRICT (cannot delete if orders exist)

### 2. Check Constraints
- `orders.status`: Must be 'pending', 'completed', or 'cancelled'
- `orders.payment_status`: Must be 'paid', 'unpaid', or 'partial'
- `order_items.quantity`: Must be greater than 0
- `payments.amount`: Must be greater than 0

### 3. Unique Constraints
- `vendors.phone`: One account per phone number
- `orders.order_number`: Human-readable unique order identifier
- `vendor_products(vendor_id, product_id)`: One product entry per vendor

### 4. Automatic Calculations
- `orders.remaining_amount`: Automatically calculated as `total_amount - amount_paid`
- `orders.payment_status`: Automatically updated based on `amount_paid` vs `total_amount`
- `orders.amount_paid`: Automatically updated when payments are inserted

---

## Performance Considerations

### Critical Indexes
1. **orders(vendor_id, delivery_date, status)** - Dashboard queries
2. **vendor_products(vendor_id, product_id)** - Inventory lookups
3. **orders(order_number)** - Order lookups
4. **customers(phone)** - Customer search
5. **orders(payment_status)** - Payment queries
6. **payments(order_id)** - Payment history lookups

### Query Optimization Tips
- Use views for complex joins (orders_full, vendor_inventory_status, order_payments_summary)
- Filter by vendor_id first in all queries
- Use date indexes for delivery_date filtering
- Consider materialized views for heavy aggregations

---

## Security & Access Control

### Row Level Security (RLS)
All tables use RLS policies to ensure:
- Vendors can only access their own data
- Orders and inventory are isolated by vendor_id
- Authenticated users have read access to products catalog
- No cross-vendor data leakage
- Payments are accessible only through vendor's orders

### Authentication Integration
- Vendor `id` matches Supabase `auth.uid()`
- Phone authentication via Supabase Auth with OTP
- Session management via SharedPreferences (test mode)

---

## Testing Data (Optional)

```sql
-- Test Vendor
INSERT INTO vendors (id, phone, name, business_name, address, is_active) VALUES
('5d4b8601-2bef-4ce3-8631-b62730d403ea', '+919876543210', 'Test Vendor', 'Test Water Service', '123 Main St, Mumbai', true);

-- Test Customers
INSERT INTO customers (id, name, phone, address, flat_number, floor, building_name) VALUES
('cust-1', 'Sivanesan V', '+919876543210', 'Lake View Society, Sector 21, Mumbai', 'A-201', '2', 'Lake View'),
('cust-2', 'Akhilan V', '+919812345678', 'Green Gardens, Near City Mall, Pune', 'B-502', '5', 'Green Gardens');

-- Test Products
INSERT INTO products (id, name, is_active) VALUES
('prod-20l', '20L Water Can', true),
('prod-10l', '10L Water Can', true);

-- Test Vendor Products
INSERT INTO vendor_products (vendor_id, product_id, selling_price, deposit_amount, current_stock, low_stock_threshold) VALUES
('5d4b8601-2bef-4ce3-8631-b62730d403ea', 'prod-20l', 70.00, 0.00, 30, 10),
('5d4b8601-2bef-4ce3-8631-b62730d403ea', 'prod-10l', 20.00, 0.00, 50, 15);

-- Test Order
INSERT INTO orders (id, order_number, vendor_id, customer_id, delivery_date, time_slot, total_amount, status, payment_status) VALUES
('order-1', '#1001', '5d4b8601-2bef-4ce3-8631-b62730d403ea', 'cust-1', CURRENT_DATE, '8:00 AM - 10:00 AM', 140.00, 'pending', 'unpaid');

-- Test Order Items
INSERT INTO order_items (id, order_id, product_id, quantity, unit_price, subtotal) VALUES
('item-1', 'order-1', 'prod-20l', 2, 70.00, 140.00);

-- Test Payment (Partial)
INSERT INTO payments (order_id, amount, payment_method, notes) VALUES
('order-1', 70.00, 'cash', 'Partial payment');
```

---

## Migration Notes

### From Test to Production
1. Set test mode flags to `false` in services
2. Verify RLS policies are active
3. Remove dummy data from tables
4. Validate indexes are created
5. Check foreign key constraints
6. Run migration scripts if upgrading from v1.0

### Schema Version Control
- Tag schema changes with version numbers
- Keep migration scripts in `/supabase/migrations`
- Document breaking changes in CLAUDE.md
- Test migrations on staging before production

---

## Support & Troubleshooting

### Common Issues

**Issue**: Orders not appearing
- Check vendor_id matches auth.uid()
- Verify RLS policies allow read access
- Confirm delivery_date format is YYYY-MM-DD

**Issue**: Stock not deducting
- Ensure vendor_products record exists
- Check product_id in order_items matches
- Verify deductStockForOrder is being called

**Issue**: Payment status not updating
- Check that payment trigger is working
- Verify amount_paid is being updated
- Check calculate_remaining_amount trigger

**Issue**: Permission denied errors
- Confirm user is authenticated
- Check RLS policy definitions
- Verify vendor_id in session matches record

---

## Appendix: Time Zones

All timestamps use `TIMESTAMPTZ` (timezone-aware). Recommended:
- Store all times in UTC
- Convert to local time in app layer
- Use consistent timezone for delivery dates

---

## Changelog

### Version 2.0 (2025-01-10)
- ✅ Added `created_at` and `updated_at` to `customers` table
- ✅ Added `updated_at` to `vendor_products` table
- ✅ Added `updated_at` to `orders` table
- ✅ Added partial payment support (`amount_paid`, `remaining_amount` fields)
- ✅ Added `payments` table for payment history
- ✅ Updated `payment_status` to include 'partial' status
- ✅ Added automatic calculation triggers for payment amounts
- ✅ Added `order_payments_summary` view
- ✅ Added RLS policies for payments table
- ✅ Fixed `orders_full` view to handle NULL items properly
- ✅ Added migration scripts for upgrading from v1.0

### Version 1.0 (Initial)
- Initial schema release

---

**Document Version**: 2.0
**Maintained By**: Development Team
**Last Updated**: 2025-01-10
