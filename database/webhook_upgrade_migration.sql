-- ============================================================
-- Migration: webhook_upgrade_add_columns
-- Adds columns required by the updated WhatsApp webhook
-- Run in Supabase SQL Editor or via supabase migration
-- ============================================================

-- 1. whatsapp_sessions: new columns for order flow & address update
ALTER TABLE whatsapp_sessions
  ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES customers(id),
  ADD COLUMN IF NOT EXISTS pending_address TEXT,
  ADD COLUMN IF NOT EXISTS can_count INTEGER,
  ADD COLUMN IF NOT EXISTS delivery_date DATE,
  ADD COLUMN IF NOT EXISTS time_slot TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- 2. customers: location + status columns for onboarding
ALTER TABLE customers
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- 3. orders: make vendor_id and order_number nullable; add new columns
ALTER TABLE orders
  ALTER COLUMN vendor_id DROP NOT NULL;

ALTER TABLE orders
  ALTER COLUMN order_number DROP NOT NULL;

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS can_count INTEGER,
  ADD COLUMN IF NOT EXISTS delivery_address TEXT,
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'portal';

-- 4. Indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_date ON orders(delivery_date);
