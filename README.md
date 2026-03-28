# Can Can Water Delivery 🚰

Monorepo for the Can Can water can delivery platform.

## Structure

```
vendor_app/
├── frontend/          # Admin portal + WhatsApp webhook (Next.js)
├── android/           # Vendor mobile app (Flutter)
├── database/          # Supabase SQL schemas and migrations
├── docs/              # Architecture and planning docs
└── _archive/          # Old code kept for reference (not used)
```

## Projects

### `frontend/` — Next.js Admin Portal & Webhook
The main web application. Does everything in one:
- **Admin portal** at `/portal` — manage vendors, customers, orders, WhatsApp config
- **WhatsApp webhook** at `/api/whatsapp/webhook` — receives inbound messages, runs the onboarding + ordering flow
- **Customer onboarding** at `/onboard` — form customers fill after scanning a QR code
- **Landing page** at `/`

**Stack**: Next.js 16, TypeScript, MUI v7, Supabase, deployed on Vercel

```bash
cd frontend
pnpm install
pnpm dev        # http://localhost:3000
```

Required env vars (copy `.env.local.example` → `.env.local`):
```
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_SUPABASE_URL=
SUPABASE_ANON_KEY=
JWT_SECRET=
WHATSAPP_API_TOKEN=
WHATSAPP_PHONE_NUMBER_ID=
WHATSAPP_WEBHOOK_SECRET=
META_APP_SECRET=
NEXT_PUBLIC_WHATSAPP_NUMBER=
NEXT_PUBLIC_BASE_URL=
```

### `android/` — Flutter Vendor App
Mobile app for vendors to manage orders, inventory, payments, and customers.

**Stack**: Flutter, Dart, Supabase SDK, Provider

```bash
cd android
flutter pub get
flutter run
```

Required env vars in `.env`:
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

## Database

SQL schemas live in `database/`. Run against your Supabase project:

```bash
# In Supabase SQL editor, run in order:
1. database/unified_schema.sql
2. database/customer_vendors_migration.sql
```

## How the QR → WhatsApp flow works

1. Vendor opens Flutter app → QR Code screen → shows a QR code
2. QR encodes: `https://wa.me/{BUSINESS_NUMBER}?text=ref-{vendorId}`
3. Customer scans → WhatsApp opens → message sends to business number
4. Next.js webhook receives it → looks up vendor, checks if customer exists
5. **New customer**: webhook sends them `https://your-domain/onboard?v={vendorId}&p={phone}` → they fill a form → account created
6. **Existing customer**: webhook links them to the vendor and opens the order menu

## Deployment

- `frontend/` → Deploy to **Vercel** (free tier is sufficient)
- Set all env vars in Vercel project settings
- Configure Meta webhook URL to: `https://your-vercel-domain.vercel.app/api/whatsapp/webhook`
- `android/` → Build APK with `flutter build apk --release`