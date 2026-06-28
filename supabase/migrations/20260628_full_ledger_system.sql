-- Full ledger system, built against the REAL production schema (verified via
-- direct psql connection — vendors/customers/orders/order_items/vendor_products
-- already exist; payments/payment_intents/commission_ledger/vendor_wallet_ledger/
-- payout_batches/payout_items/settlement_policy do NOT exist at all, despite
-- being referenced throughout frontend/src/lib/finance-ledger.ts,
-- payout-engine.ts, cashfree-payouts.ts, and the WhatsApp webhook's commission
-- calculation). This replaces 20260618_marketplace_payments_unified.sql,
-- which assumed `payments` already existed and only ALTERed it — a no-op
-- against this database since the table was never created.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- Orders financial snapshot fields
-- ---------------------------------------------------------------------------
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS gross_amount NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS platform_commission_amount NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS vendor_net_amount NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS gateway_fee_amount NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS amount_paid NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS remaining_amount NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS pricing_version TEXT DEFAULT 'v1',
  ADD COLUMN IF NOT EXISTS financial_snapshot JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS payment_state TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS payment_method TEXT,
  ADD COLUMN IF NOT EXISTS payment_reference TEXT,
  ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_idempotency_key_unique
  ON orders(idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_orders_payment_state ON orders(payment_state);
CREATE INDEX IF NOT EXISTS idx_orders_payment_method ON orders(payment_method);

-- ---------------------------------------------------------------------------
-- Vendor payout details (bank/UPI for Cashfree Payouts beneficiary)
-- ---------------------------------------------------------------------------
ALTER TABLE vendors
  ADD COLUMN IF NOT EXISTS bank_account_number TEXT,
  ADD COLUMN IF NOT EXISTS bank_ifsc TEXT,
  ADD COLUMN IF NOT EXISTS bank_account_holder_name TEXT,
  ADD COLUMN IF NOT EXISTS payout_vpa TEXT,
  ADD COLUMN IF NOT EXISTS cf_beneficiary_id TEXT;

-- ---------------------------------------------------------------------------
-- Settlement policy (global and vendor-specific commission rules)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS settlement_policy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID REFERENCES vendors(id) ON DELETE CASCADE,
  policy_name TEXT NOT NULL,
  commission_type TEXT NOT NULL DEFAULT 'per_bottle' CHECK (commission_type IN ('per_bottle', 'percentage')),
  per_bottle_commission NUMERIC(10,2) DEFAULT 0,
  commission_percentage NUMERIC(6,3) DEFAULT 0,
  pg_fee_borne_by TEXT NOT NULL DEFAULT 'platform' CHECK (pg_fee_borne_by IN ('platform', 'vendor', 'shared')),
  settlement_cycle TEXT NOT NULL DEFAULT 'T+2',
  hold_days INTEGER NOT NULL DEFAULT 0,
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_settlement_policy_vendor_id ON settlement_policy(vendor_id);
CREATE INDEX IF NOT EXISTS idx_settlement_policy_active ON settlement_policy(is_active);

ALTER TABLE settlement_policy ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendors can view own settlement policy" ON settlement_policy;
CREATE POLICY "Vendors can view own settlement policy" ON settlement_policy
  FOR SELECT TO public USING (vendor_id = auth.uid() OR vendor_id IS NULL);

-- ---------------------------------------------------------------------------
-- Payment intents (checkout session tracking)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payment_intents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  vendor_id UUID REFERENCES vendors(id) ON DELETE SET NULL,
  provider TEXT NOT NULL DEFAULT 'razorpay',
  provider_order_id TEXT,
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',
  status TEXT NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'requires_action', 'paid', 'failed', 'expired', 'cancelled')),
  checkout_url TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  idempotency_key TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(order_id, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_payment_intents_order_id ON payment_intents(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_intents_status ON payment_intents(status);
CREATE INDEX IF NOT EXISTS idx_payment_intents_provider_order_id ON payment_intents(provider_order_id);

ALTER TABLE payment_intents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendors can view own payment intents" ON payment_intents;
CREATE POLICY "Vendors can view own payment intents" ON payment_intents
  FOR SELECT TO public USING (vendor_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Payments (did NOT exist — created fresh with full marketplace field set)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  payment_intent_id UUID REFERENCES payment_intents(id) ON DELETE SET NULL,
  vendor_id UUID REFERENCES vendors(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  provider TEXT,
  provider_payment_id TEXT,
  provider_transfer_id TEXT,
  collection_mode TEXT DEFAULT 'online' CHECK (collection_mode IN ('online', 'cash_platform', 'cash_vendor')),
  payment_method TEXT,
  payment_method_detail TEXT,
  amount NUMERIC(12,2) NOT NULL,
  gateway_fee NUMERIC(12,2) DEFAULT 0,
  gateway_tax NUMERIC(12,2) DEFAULT 0,
  platform_commission NUMERIC(12,2) DEFAULT 0,
  vendor_payable NUMERIC(12,2) DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  is_reconciled BOOLEAN DEFAULT false,
  reconciled_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  idempotency_key TEXT,
  captured_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_vendor_id ON payments(vendor_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_provider_payment_id ON payments(provider_payment_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_provider_payment_unique
  ON payments(provider, provider_payment_id)
  WHERE provider IS NOT NULL AND provider_payment_id IS NOT NULL;

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendors can view own payments" ON payments;
CREATE POLICY "Vendors can view own payments" ON payments
  FOR SELECT TO public USING (vendor_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Commission ledger
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commission_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  commission_type TEXT NOT NULL CHECK (commission_type IN ('per_bottle', 'percentage')),
  qty INTEGER NOT NULL DEFAULT 0,
  per_bottle_commission NUMERIC(10,2) DEFAULT 0,
  commission_percentage NUMERIC(6,3) DEFAULT 0,
  gross_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  commission_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  net_vendor_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accrued', 'settled', 'reversed')),
  rule_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(order_id)
);

CREATE INDEX IF NOT EXISTS idx_commission_ledger_vendor_id ON commission_ledger(vendor_id);
CREATE INDEX IF NOT EXISTS idx_commission_ledger_status ON commission_ledger(status);
CREATE INDEX IF NOT EXISTS idx_commission_ledger_created_at ON commission_ledger(created_at);

ALTER TABLE commission_ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendors can view own commission ledger" ON commission_ledger;
CREATE POLICY "Vendors can view own commission ledger" ON commission_ledger
  FOR SELECT TO public USING (vendor_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Vendor wallet ledger (append-only accounting)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS vendor_wallet_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  payout_item_id UUID,
  entry_type TEXT NOT NULL CHECK (entry_type IN ('credit', 'debit', 'hold', 'release', 'reversal')),
  source_type TEXT NOT NULL CHECK (source_type IN ('online_payment', 'cash_collection', 'commission', 'payout', 'adjustment', 'refund')),
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',
  balance_after NUMERIC(12,2),
  status TEXT NOT NULL DEFAULT 'posted' CHECK (status IN ('pending', 'posted', 'cancelled')),
  notes TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vendor_wallet_ledger_vendor_id ON vendor_wallet_ledger(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_wallet_ledger_created_at ON vendor_wallet_ledger(created_at);
CREATE INDEX IF NOT EXISTS idx_vendor_wallet_ledger_status ON vendor_wallet_ledger(status);

ALTER TABLE vendor_wallet_ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendors can view own wallet ledger" ON vendor_wallet_ledger;
CREATE POLICY "Vendors can view own wallet ledger" ON vendor_wallet_ledger
  FOR SELECT TO public USING (vendor_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Payout orchestration tables
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payout_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL DEFAULT 'cashfree',
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'processing', 'partially_paid', 'paid', 'failed', 'cancelled')),
  settlement_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_vendors INTEGER NOT NULL DEFAULT 0,
  total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  processed_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  failed_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payout_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES payout_batches(id) ON DELETE CASCADE,
  vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
  provider TEXT NOT NULL DEFAULT 'cashfree',
  provider_payout_id TEXT,
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'processing', 'paid', 'failed', 'reversed')),
  failure_reason TEXT,
  initiated_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payout_items_batch_id ON payout_items(batch_id);
CREATE INDEX IF NOT EXISTS idx_payout_items_vendor_id ON payout_items(vendor_id);
CREATE INDEX IF NOT EXISTS idx_payout_items_status ON payout_items(status);

DO $$
BEGIN
  ALTER TABLE vendor_wallet_ledger
    ADD CONSTRAINT fk_vendor_wallet_ledger_payout_item
    FOREIGN KEY (payout_item_id) REFERENCES payout_items(id) ON DELETE SET NULL;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE payout_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendors can view own payout items" ON payout_items;
CREATE POLICY "Vendors can view own payout items" ON payout_items
  FOR SELECT TO public USING (vendor_id = auth.uid());
-- payout_batches has no vendor_id (one batch covers many vendors) — only
-- service_role (admin backend) touches it directly; no client-facing policy needed.

-- ---------------------------------------------------------------------------
-- Atomic wallet append helper to avoid race conditions on balance_after.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION append_vendor_wallet_entry(
  p_vendor_id UUID,
  p_order_id UUID DEFAULT NULL,
  p_payment_id UUID DEFAULT NULL,
  p_payout_item_id UUID DEFAULT NULL,
  p_entry_type TEXT DEFAULT 'credit',
  p_source_type TEXT DEFAULT 'online_payment',
  p_amount NUMERIC DEFAULT 0,
  p_status TEXT DEFAULT 'posted',
  p_notes TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS vendor_wallet_ledger
LANGUAGE plpgsql
AS $$
DECLARE
  prev_balance NUMERIC := 0;
  signed_amount NUMERIC := 0;
  inserted_row vendor_wallet_ledger;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(p_vendor_id::text));

  SELECT COALESCE(balance_after, 0)
    INTO prev_balance
    FROM vendor_wallet_ledger
    WHERE vendor_id = p_vendor_id
    ORDER BY created_at DESC
    LIMIT 1
    FOR UPDATE;

  IF p_entry_type IN ('debit', 'reversal') THEN
    signed_amount := -ABS(p_amount);
  ELSE
    signed_amount := ABS(p_amount);
  END IF;

  INSERT INTO vendor_wallet_ledger (
    vendor_id, order_id, payment_id, payout_item_id, entry_type, source_type,
    amount, balance_after, status, notes, metadata
  )
  VALUES (
    p_vendor_id, p_order_id, p_payment_id, p_payout_item_id, p_entry_type, p_source_type,
    ABS(p_amount), (prev_balance + signed_amount), p_status, p_notes, COALESCE(p_metadata, '{}'::jsonb)
  )
  RETURNING * INTO inserted_row;

  RETURN inserted_row;
END;
$$;

-- ---------------------------------------------------------------------------
-- Reconciliation controls
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reconciliation_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_type TEXT NOT NULL CHECK (run_type IN ('payments', 'payouts', 'full')),
  status TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ,
  summary JSONB NOT NULL DEFAULT '{}'::jsonb,
  error_message TEXT
);

CREATE TABLE IF NOT EXISTS reconciliation_issues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id UUID NOT NULL REFERENCES reconciliation_runs(id) ON DELETE CASCADE,
  issue_type TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'warning' CHECK (severity IN ('info', 'warning', 'critical')),
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  payout_item_id UUID REFERENCES payout_items(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  expected_payload JSONB,
  actual_payload JSONB,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'ignored')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_reconciliation_issues_run_id ON reconciliation_issues(run_id);
CREATE INDEX IF NOT EXISTS idx_reconciliation_issues_status ON reconciliation_issues(status);
CREATE INDEX IF NOT EXISTS idx_reconciliation_issues_severity ON reconciliation_issues(severity);

-- ---------------------------------------------------------------------------
-- Compatibility view for existing admin commissions APIs
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW commissions AS
SELECT
  cl.id,
  cl.order_id,
  cl.vendor_id,
  cl.commission_amount,
  cl.gross_amount AS order_total,
  CASE
    WHEN cl.commission_type = 'percentage' THEN cl.commission_percentage
    ELSE 0
  END AS commission_rate,
  CASE
    WHEN cl.status = 'pending' THEN 'pending'
    WHEN cl.status = 'accrued' THEN 'processing'
    WHEN cl.status = 'settled' THEN 'paid'
    ELSE 'cancelled'
  END AS status,
  cl.created_at,
  NULL::timestamptz AS paid_at,
  o.delivery_date AS order_date
FROM commission_ledger cl
LEFT JOIN orders o ON o.id = cl.order_id;

COMMIT;
