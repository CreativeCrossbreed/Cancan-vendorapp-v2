# Payment Gateway Operations Runbook

## Environment Variables

Add these in `frontend/.env`:

- `PAYMENT_PROVIDER_DEFAULT=razorpay`
- `PAYMENT_INTERNAL_TOKEN=<long-random-secret>`
- `DEFAULT_PER_BOTTLE_COMMISSION=1`
- `DEFAULT_BOTTLE_PRICE=30`
- `RECONCILIATION_API_BASE=http://localhost:3000`

Provider-specific:

- Razorpay:
  - `RAZORPAY_KEY_ID`
  - `RAZORPAY_KEY_SECRET`
  - `RAZORPAY_WEBHOOK_SECRET`
- Cashfree:
  - `CASHFREE_APP_ID`
  - `CASHFREE_SECRET_KEY`
  - `CASHFREE_WEBHOOK_SECRET`

Optional:

- `ENABLE_REAL_PAYOUTS=true` (otherwise payout engine runs in mock-safe mode)

## API Endpoints

- Create payment intent: `POST /api/payments/create-intent`
- Provider webhook: `POST /api/payments/webhook`
- Cash collected by platform: `POST /api/payments/cash-collect`
- Trigger payout batch: `POST /api/payouts/run`
- List payout batches: `GET /api/payouts`
- Trigger reconciliation: `POST /api/reconciliation/run`
- List reconciliation issues: `GET /api/reconciliation/issues`

## Daily Operations

1. Run payout batch
   - `npm run payments:payout`
2. Run reconciliation
   - `npm run payments:reconcile`
3. Check issues
   - Open `/api/reconciliation/issues?status=open`

## Suggested Cron

- Payout batch (daily 6:30 PM):
  - `30 18 * * * cd /path/to/frontend && npm run payments:payout`
- Reconciliation (daily 7:00 PM):
  - `0 19 * * * cd /path/to/frontend && npm run payments:reconcile`

## Exception Handling

If reconciliation reports open issues:

1. `payment_amount_mismatch`
   - Verify order snapshot (`gross_amount`) and gateway payload.
2. `orphan_payment`
   - Validate webhook mapping by `provider_order_id`.
3. `payout_ledger_mismatch`
   - Verify `payout_items` and matching `vendor_wallet_ledger` debit entries.

Keep issue lifecycle in `reconciliation_issues.status` (`open`, `resolved`, `ignored`) with operator notes in tooling.
