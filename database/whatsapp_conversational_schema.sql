-- Run this in your Supabase SQL Editor to support the WhatsApp State Machine

-- Create the sessions table to track conversational onboarding
CREATE TABLE IF NOT EXISTS whatsapp_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) UNIQUE NOT NULL,
  
  -- The current step of the conversational flow
  -- Expected states: 'awaiting_name', 'awaiting_location', 'awaiting_address', 'active'
  state VARCHAR(50) NOT NULL DEFAULT 'awaiting_name',
  
  -- Temporary storage for collected data before user profile is complete
  name VARCHAR(255),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  address TEXT,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Note: In older references there was a `whatsapp_messages` table. 
-- Ensure it exists to track inbound/outbound logs.
CREATE TABLE IF NOT EXISTS whatsapp_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id TEXT NOT NULL,
  customer_phone VARCHAR(20) NOT NULL,
  message_type VARCHAR(50) NOT NULL,
  message_content TEXT,
  direction VARCHAR(20) CHECK (direction IN ('inbound', 'outbound')),
  status VARCHAR(20) DEFAULT 'sent',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Trigger to update timestamp
CREATE OR REPLACE FUNCTION update_whatsapp_session_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_whatsapp_session ON whatsapp_sessions;
CREATE TRIGGER trigger_update_whatsapp_session
    BEFORE UPDATE ON whatsapp_sessions
    FOR EACH ROW EXECUTE FUNCTION update_whatsapp_session_timestamp();
