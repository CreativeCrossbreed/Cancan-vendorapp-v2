# Webhook Integration Walkthrough

## What Changed

### 1. Database Migration (Supabase)

Applied migration `webhook_upgrade_add_columns` adding:

| Table | New Columns |
|---|---|
| `whatsapp_sessions` | `customer_id`, `pending_address`, `can_count`, `delivery_date`, `time_slot`, `updated_at` |
| `customers` | `latitude`, `longitude`, `is_verified`, `is_active` |
| `orders` | `can_count`, `delivery_address`, `latitude`, `longitude`, `source`; made `vendor_id` + `order_number` nullable |

Local SQL copy: [webhook_upgrade_migration.sql](file:///d:/vendor_app/database/webhook_upgrade_migration.sql)

### 2. Webhook Route Replacement

Replaced [route.ts](file:///d:/vendor_app/frontend/src/app/api/whatsapp/webhook/route.ts) (328 → 1085 lines). New features:

- **Full Order Flow**: can count → date → time slot → confirmation → `orders` table insert
- **Repeat Last Order**: prefills last order, lets customer confirm or change time slot
- **My Deliveries**: shows last 5 orders from past 30 days with status emojis
- **Update Address**: location pin → reverse geocode → confirm/edit flow
- **Help Menu**: delivery issue, wrong order, contact vendor, Can Can support
- **Outbound Notifications**: `notifyOrderAccepted()`, `notifyOrderDelivered()`, `notifyDeliveryFailed()` — exported functions to call from vendor portal

### 3. Fixes Applied

- Wired missing `repeat_awaiting_choice` / `repeat_awaiting_time_slot` states into `handleActiveSession`
- Fixed `getCustomerVendor` nested join access (TS errors)
- Cleaned lint: `node:crypto`, `Number.parseInt`/`Number.isNaN`, removed unused `sendInteractiveList` import

## Verification

- ✅ `npx tsc --noEmit` — zero errors
- ⚠️ **Manual testing needed**: send "hi" from WhatsApp to verify the main menu renders with all 5 options after deploying to Vercel

## TODO for You

1. **Replace `reverseGeocode()`** with real Google Maps API call (bottom of route.ts, line ~1070)
2. **Deploy to Vercel** and test the flow end-to-end via WhatsApp
3. **Hook up notification functions** — call `notifyOrderAccepted`/`notifyOrderDelivered`/`notifyDeliveryFailed` from your vendor portal when order status changes
