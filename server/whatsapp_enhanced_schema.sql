-- Enhanced WhatsApp system database schema

-- Drop existing tables if they exist for clean migration
DROP TABLE IF EXISTS whatsapp_sessions CASCADE;
DROP TABLE IF EXISTS whatsapp_reservations CASCADE;

-- WhatsApp session tracking table
CREATE TABLE IF NOT EXISTS whatsapp_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_phone VARCHAR(20) NOT NULL,
  customer_id UUID REFERENCES customers(id),
  current_vendor_id UUID REFERENCES vendors(id),
  session_state VARCHAR(50) NOT NULL DEFAULT 'vendor_confirmation',
  session_data JSONB DEFAULT '{}',
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Inventory reservation table
CREATE TABLE IF NOT EXISTS whatsapp_reservations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES whatsapp_sessions(id),
  vendor_id UUID REFERENCES vendors(id),
  product_id UUID REFERENCES products(id),
  quantity_reserved INTEGER NOT NULL,
  reserved_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'reserved'
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_whatsapp_sessions_customer_phone ON whatsapp_sessions(customer_phone);
CREATE INDEX IF NOT EXISTS idx_whatsapp_sessions_status ON whatsapp_sessions(status);
CREATE INDEX IF NOT EXISTS idx_whatsapp_reservations_session_id ON whatsapp_reservations(session_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_reservations_vendor_product ON whatsapp_reservations(vendor_id, product_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_reservations_expires_at ON whatsapp_reservations(expires_at);

-- Function to clean up expired reservations
CREATE OR REPLACE FUNCTION cleanup_expired_reservations()
RETURNS void AS $$
BEGIN
  UPDATE whatsapp_reservations
  SET status = 'expired'
  WHERE status = 'reserved'
  AND expires_at < now();
END;
$$ LANGUAGE plpgsql;