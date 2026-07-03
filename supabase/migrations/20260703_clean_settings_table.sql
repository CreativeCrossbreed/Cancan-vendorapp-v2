-- ============================================================================
-- Clean settings table — proper home for app configuration/secrets.
-- Replaces the interim hack of storing the WhatsApp token + Cashfree creds in
-- disguised whatsapp_sessions rows (phone_number '__wa_config__'/'__cf_config__').
--
-- Read by the backend (service role) only; RLS on with no public policy so the
-- anon key can never read secrets.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.settings (
  key         text PRIMARY KEY,
  value       text,
  description text,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
-- No policies: service-role-only. Service role bypasses RLS.

-- Seed the current working config (migrated from the whatsapp_sessions hack).
INSERT INTO public.settings (key, value, description) VALUES
  ('whatsapp_api_token',        '', 'Meta WhatsApp Cloud API permanent token (System User "Employee")'),
  ('whatsapp_phone_number_id',  '', 'Production WhatsApp phone number id (number 919025320535)'),
  ('cashfree_app_id',           '', 'Cashfree App ID (test or live)'),
  ('cashfree_secret_key',       '', 'Cashfree Secret Key'),
  ('cashfree_base_url',         'https://sandbox.cashfree.com/pg', 'https://api.cashfree.com/pg for live'),
  ('payment_provider_default',  'cashfree', 'razorpay | cashfree'),
  ('support_phone_number',      '', 'Human support contact shown to customers')
ON CONFLICT (key) DO NOTHING;
