# Can Can — Architecture Map

Plain-English map of the whole system, written after a deep debugging pass.
If you read nothing else about this project, read this.

## What it is
A water-can delivery service. Customers order over **WhatsApp**, vendors fulfil
and deliver via a **Flutter app**, an **admin portal** oversees everything.
Payments are **cash on delivery** (primary) or **online via Cashfree** (optional).

## The pieces
| Piece | Tech | Where it lives | What it does |
|---|---|---|---|
| WhatsApp bot | Next.js API route | `frontend/src/app/api/whatsapp/webhook/route.ts` (on Vercel, `cancanindia.com`) | Receives customer messages from Meta, runs the ordering conversation, writes orders |
| Vendor app | Flutter | `lib/` | Vendors log in, see orders, mark delivered, record payments, manage inventory |
| Admin portal | Next.js pages | `frontend/src/app/portal/*` | Approve vendors, view orders/customers/dashboards |
| Backend API | Next.js API routes | `frontend/src/app/api/*` | ~45 endpoints serving admin + app + payments |
| Database | Supabase (Postgres) | project `eaycmealjxjbobzbryfs` | Single shared DB for everything |
| Hosting | Vercel (Hobby) | `cancan-vendorapp-v2` (Sudhir's team) | Auto-deploys `main`; deploy hook available |

## The core data (the ~11 tables that matter)
| Table | Holds |
|---|---|
| `customers` | People who order. `vendor_id` = their owning vendor |
| `vendors` | Delivery businesses. `approval_status`, `is_on_vacation`, `working_hours` |
| `products` | Water can catalogue (brand + size) |
| `vendor_products` | Which products a vendor sells, `selling_price`, `current_stock` |
| `orders` | One order. `status`, `time_slot`, `delivery_date`, `payment_state` |
| `order_items` | Line items of an order (product, qty, price) |
| `payments` / `payment_intents` | Money in — cash record or Cashfree online payment |
| `whatsapp_sessions` | The bot's per-customer conversation state (the ordering flow) |
| `whatsapp_messages` | Log of every inbound/outbound WhatsApp message (also dedup) |
| `admin_users` | Admin portal logins |
| `device_tokens` | For push notifications to vendors |

## Dead weight (built, never used — safe to remove later, with care)
All of these had **0 rows** as of the audit — an entire fintech settlement
system that was never turned on:
`payout_batches`, `payout_items`, `reconciliation_runs`, `reconciliation_issues`,
`settlement_policy`, `vendor_wallet_ledger`, `transactions`, `suppliers`,
`inventory_logs`, `audit_logs`, `vendor_users`, plus dead old-bot leftovers
`simple_orders` and `users`, and a **duplicate** commission table
(`commissions` vs `commission_ledger` — keep one).

⚠️ CAVEAT: the Flutter app has code paths referencing `vendor_wallet_ledger` and
`payout_items`. Those must be removed from the app **before** dropping the
tables, or an earnings/payout screen will error. Do not blind-drop.

## The WhatsApp ordering flow (the state machine)
Session `state` in `whatsapp_sessions` walks:
```
(no session) → hi → main menu
  New Order  → awaiting_brand → awaiting_can_count → awaiting_date
             → awaiting_time_slot → awaiting_confirmation → [place order]
             → awaiting_payment_choice → (Pay Online link | Cash on Delivery) → done
  Repeat Last Order → repeat_awaiting_choice → (confirm | change slot) → [place order] → payment
  Update Address → update_address_location → update_address_confirm → done
  My Deliveries → (read-only list)
Reset words (hi/menu/cancel/stop/back...) from ANY state → back to main menu
```

## Where config/secrets live
- **Right now (interim):** WhatsApp token + Cashfree keys are in disguised
  `whatsapp_sessions` rows (`phone_number = '__wa_config__'` / `'__cf_config__'`).
  This was a pragmatic hack because DDL couldn't be run remotely.
- **Target:** a proper `settings` table (migration `20260703_clean_settings_table.sql`).
- Read by `frontend/src/lib/whatsapp.ts` (`getWhatsAppCredentials`) and
  `frontend/src/lib/payment-gateway.ts` (`getCashfreeConfig`), both with env fallback.

## How code goes live (important — this bit is fragile)
- Push to `main` on `CreativeCrossbreed/Cancan-vendorapp-v2` → Vercel builds.
- Production is `cancanindia.com`. It should auto-deploy from `main`, but has
  lagged; a **deploy hook** force-deploys production.
- ⚠️ A green build ≠ live. Always verify the **production** commit, and verify
  the bot sends a real `sent` reply — not just that a DB state changed.

## Known gotchas (hard-won tonight)
1. **Cold starts (Hobby, ~10s limit):** the webhook can be killed mid-reply when
   idle. Mitigated by: retry-safe dedup (a killed attempt recovers on Meta's
   retry), lean processing, and a keep-warm ping. Symptom of regression:
   "only replies while being actively used."
2. **Dedup must mark 'processed' only AFTER replying** — else a killed first
   attempt permanently blocks all retries (message never answered).
3. **Session writes key on `phone_number`, not row `id`** — ids churn on
   double-taps and would drop updates.
4. **Cashfree uses the Payment LINKS api** (`/links` → shareable `link_url`),
   not the Orders api (returns only a session id needing their JS SDK).
5. **Cashfree is on TEST keys** — no real money until live keys are set.
