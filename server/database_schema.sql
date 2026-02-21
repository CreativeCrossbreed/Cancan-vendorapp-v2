-- Admin users table for authentication
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'operations',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_login TIMESTAMP WITH TIME ZONE
);

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

-- Commission tracking table
CREATE TABLE IF NOT EXISTS commission_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id),
  vendor_id UUID REFERENCES vendors(id),
  commission_amount DECIMAL(10,2) NOT NULL,
  order_amount DECIMAL(10,2) NOT NULL,
  commission_rate DECIMAL(5,2) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  paid_at TIMESTAMP WITH TIME ZONE
);

-- Add commission_rate to vendors table if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'vendors' AND column_name = 'commission_rate'
  ) THEN
    ALTER TABLE vendors ADD COLUMN commission_rate DECIMAL(5,2) DEFAULT 10.0;
    ALTER TABLE vendors ADD COLUMN status VARCHAR(20) DEFAULT 'active';
  END IF;
END $$;

-- Add status to customers table if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'customers' AND column_name = 'status'
  ) THEN
    ALTER TABLE customers ADD COLUMN status VARCHAR(20) DEFAULT 'active';
  END IF;
END $$;

-- Insert default admin user (password: admin123)
INSERT INTO admin_users (email, password, role)
VALUES (
  'admin@cancan.com',
  '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/8xq9cLKSa',
  'super_admin'
) ON CONFLICT (email) DO NOTHING;

-- Insert default WhatsApp config
INSERT INTO whatsapp_config (api_key, webhook_secret, phone_number_id, business_account_id)
VALUES (
  'your_whatsapp_api_token_here',
  'your_webhook_secret_here',
  'your_phone_number_id_here',
  'your_business_account_id_here'
) ON CONFLICT DO NOTHING;