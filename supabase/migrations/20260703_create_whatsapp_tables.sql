-- WhatsApp message deduplication log
CREATE TABLE IF NOT EXISTS public.whatsapp_messages (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  message_id text UNIQUE NOT NULL,
  customer_phone text NOT NULL,
  message_type text NOT NULL DEFAULT 'text',
  message_content text,
  direction text NOT NULL DEFAULT 'inbound' CHECK (direction IN ('inbound', 'outbound')),
  status text NOT NULL DEFAULT 'received',
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_message_id ON public.whatsapp_messages(message_id);
CREATE INDEX IF NOT EXISTS idx_whatsapp_messages_customer_phone ON public.whatsapp_messages(customer_phone);

-- WhatsApp conversation session state
CREATE TABLE IF NOT EXISTS public.whatsapp_sessions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_phone text UNIQUE NOT NULL,
  state text NOT NULL DEFAULT 'idle',
  data jsonb DEFAULT '{}',
  vendor_ref text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_whatsapp_sessions_customer_phone ON public.whatsapp_sessions(customer_phone);

-- RLS: service role only (webhook uses service role key)
ALTER TABLE public.whatsapp_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.whatsapp_sessions ENABLE ROW LEVEL SECURITY;

-- Allow service role full access (bypasses RLS by default)
-- No additional policies needed for service-role-only tables
