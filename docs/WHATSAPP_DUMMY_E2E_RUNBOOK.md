# WhatsApp Dummy Source E2E Runbook

This runbook provides a repeatable way to populate vendor app data end-to-end using a dummy WhatsApp source.

## 1) Prerequisites

- Flutter vendor app running (Android emulator/phone recommended for performance).
- Frontend API server running, because simulator posts to:
  - `POST /api/whatsapp/webhook`
- Environment variables available for scripts (service-role access):
  - `SUPABASE_URL` (or `NEXT_PUBLIC_SUPABASE_URL`)
  - `SUPABASE_SERVICE_ROLE_KEY`

Example server start:

```bash
cd frontend
npm run dev
```

## 2) Safety model for current database usage

- Every run must use `--test-run-id`.
- Test records are tagged via deterministic phone numbers and message-id prefix:
  - Phone pattern generated from run id
  - Message IDs prefixed with `e2e_<runId>_`
- Every run writes a manifest:
  - `frontend/scripts/e2e/manifests/<runId>.json`
- Cleanup consumes the manifest and supports dry-run.

## 3) Simulator scenarios (real webhook path)

From repo root:

```bash
cd frontend
```

### A) Single customer onboarding + first order

```bash
npm run e2e:wa:simulate -- \
  --base-url http://localhost:3000 \
  --test-run-id run-home-001 \
  --vendor-id <VENDOR_UUID> \
  --scenario onboarding-order
```

Expected vendor app impact:
- Home tab: pending order count increases
- Home earnings and cans update

### B) Repeat order flow

```bash
npm run e2e:wa:simulate -- \
  --base-url http://localhost:3000 \
  --test-run-id run-repeat-001 \
  --vendor-id <VENDOR_UUID> \
  --scenario repeat-order
```

Expected vendor app impact:
- Additional pending order from repeat flow

### C) Multiple customers

```bash
npm run e2e:wa:simulate -- \
  --base-url http://localhost:3000 \
  --test-run-id run-multi-001 \
  --vendor-id <VENDOR_UUID> \
  --scenario multi-customer \
  --customers 5
```

Expected vendor app impact:
- Home list populated with multiple orders/customers

## 4) Direct seed helper (optional edge states)

Use only when webhook flow is not enough for a specific tab test.

### A) Unpaid completed orders (Payments tab)

```bash
npm run e2e:wa:seed -- \
  --test-run-id run-payments-001 \
  --vendor-id <VENDOR_UUID> \
  --scenario unpaid-orders \
  --count 3
```

Expected vendor app impact:
- Payments tab shows pending amount and unpaid customers

### B) Low stock / out of stock (Inventory tab)

```bash
npm run e2e:wa:seed -- \
  --test-run-id run-inventory-001 \
  --vendor-id <VENDOR_UUID> \
  --scenario low-stock \
  --count 2
```

Expected vendor app impact:
- Inventory tab shows low-stock or out-of-stock indicators

## 5) Cleanup

### Preview cleanup (safe)

```bash
npm run e2e:wa:cleanup -- --test-run-id run-home-001 --dry-run
```

### Execute cleanup

```bash
npm run e2e:wa:cleanup -- --test-run-id run-home-001 --confirm
```

## 6) Tab-by-tab E2E validation checklist

### Home tab
- Pending orders list shows seeded WhatsApp orders
- Summary cards (`to_be_delivered`, `earnings`) match expected totals
- Refresh updates values after status changes

### History tab
- Change status from admin/mobile flow to `completed` and `cancelled`
- Verify filter/day-range behavior and totals

### Payments tab
- Seed unpaid completed orders
- Verify pending total and per-customer pending amounts
- Mark partial/full payment and verify recalculation

### Inventory tab
- Seed low-stock rows in `vendor_products`
- Verify badges, edit/update stock actions, and refresh behavior

## 7) Troubleshooting

- `Webhook POST failed`: frontend API server not running or wrong `--base-url`.
- Empty vendor app after simulator run:
  - confirm `--vendor-id` matches signed-in vendor
  - verify run manifest for created records
- Cleanup says manifest not found:
  - verify run id and file at `frontend/scripts/e2e/manifests/`.
