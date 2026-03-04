-- ============================================
-- CUSTOMER-VENDOR JUNCTION TABLE
-- Links customers to their respective vendors (via QR code scan)
-- ============================================

CREATE TABLE IF NOT EXISTS customer_vendors (
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  referral_source VARCHAR(50) DEFAULT 'qr_code' CHECK (referral_source IN ('qr_code', 'whatsapp', 'manual', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  PRIMARY KEY (customer_id, vendor_id)
);

-- Enable RLS
ALTER TABLE customer_vendors ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_customer_vendors_customer ON customer_vendors(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_vendors_vendor ON customer_vendors(vendor_id);

-- Allow the service role (server-side) to manage this table
-- The onboarding API uses supabaseAdmin (service role), so no restrictive policies needed for inserts
CREATE POLICY "Service role full access" ON customer_vendors
  FOR ALL USING (true) WITH CHECK (true);
