-- Vendor-facing customer database needs lift-access (affects delivery
-- effort/time). Deposit amount is NOT added here — the real production
-- schema already has `customers.deposit_paid` for exactly this purpose
-- (refundable can deposit), so the app reuses that column instead of
-- creating a duplicate `deposit_amount` column.

ALTER TABLE IF EXISTS customers
  ADD COLUMN IF NOT EXISTS has_lift BOOLEAN;
