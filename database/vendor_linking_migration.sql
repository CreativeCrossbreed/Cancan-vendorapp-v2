-- Run this in your Supabase SQL Editor to add vendor linking support

-- 1. Add vendor_id to whatsapp_sessions so we can track which vendor the customer came from
ALTER TABLE whatsapp_sessions
  ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES vendors(id);

-- 2. Create customer_vendors join table (many-to-many: one customer can have multiple vendors)
CREATE TABLE IF NOT EXISTS customer_vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE(customer_id, vendor_id)
);

-- 3. Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_customer_vendors_customer ON customer_vendors(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_vendors_vendor ON customer_vendors(vendor_id);

-- 4. Index for rate limiting query (messages by phone + direction + time)
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_rate_limit
  ON whatsapp_messages(customer_phone, direction, created_at);

-- 5. Unique index on message_id for deduplication
CREATE UNIQUE INDEX IF NOT EXISTS idx_whatsapp_messages_dedup
  ON whatsapp_messages(message_id);
