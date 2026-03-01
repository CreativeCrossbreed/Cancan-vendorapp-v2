# Supabase Setup Guide for Can Can Vendor App

This guide will walk you through connecting your Flutter app to Supabase database.

---

## 📋 Table of Contents

1. [Create Supabase Account](#1-create-supabase-account)
2. [Create a New Project](#2-create-a-new-project)
3. [Get Your Credentials](#3-get-your-credentials)
4. [Configure the App](#4-configure-the-app)
5. [Set Up Database](#5-set-up-database)
6. [Enable Phone Authentication](#6-enable-phone-authentication)
7. [Test the Connection](#7-test-the-connection)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Create Supabase Account

### Steps:

1. Go to **https://supabase.com**
2. Click **"Start your project"** or **"Sign Up"**
3. Choose one of the following:
   - **Continue with GitHub** (recommended for developers)
   - **Continue with Google**
   - **Sign up with email**

4. If you signed up with email, check your inbox for verification email
5. Create a password for your account

6. After signing in, you'll be redirected to your dashboard

> **💡 Tip**: Supabase offers a generous free tier:
> - 500 MB database storage
> - 1 GB file storage
> - 2 GB bandwidth/month
> - 50,000 MAUs (Monthly Active Users)
>
> Perfect for small to medium water delivery businesses!

---

## 2. Create a New Project

### Steps:

1. On your Supabase dashboard, click **"New Project"** button

2. **Organization Settings** (if first project):
   - Enter organization name: e.g., "Can Can Water Delivery"
   - Click **"Create organization"**

3. **Create Project**:
   - **Name**: `Can Can Vendor` (or your preferred name)
   - **Database Password**: ⚠️ **SAVE THIS PASSWORD** - you'll need it for direct database access
     - Example: `YourSecurePassword123!`
   - **Region**: Choose the region closest to your customers
     - For India: 🇮🇳 **Singapore** (recommended)
     - For USA: 🇺🇸 **North Virginia** or **Oregon**
     - For Europe: 🇪🇺 **Frankfurt** or **Ireland**
     - For global: Choose any, latency difference is minimal for most apps

4. **Pricing Plan**:
   - Select **"Free"** tier (default)
   - Click **"Create new project"**

5. **Wait for setup** (takes 1-2 minutes)
   - You'll see a progress bar
   - Wait until you see "Your project is ready"

---

## 3. Get Your Credentials

### Steps:

1. On your project dashboard, click the **gear icon (⚙️)** in the left sidebar
   - Or go directly to **Settings** → **API**

2. You'll see a page with API credentials

3. **Copy these values**:

   **Project URL:**
   ```
   https://xxxxxxxxxxxxx.supabase.co
   ```

   **anon public key:**
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

4. **Keep this page open** - you'll need these credentials in the next step

> **⚠️ Important Security Notes:**
> - **NEVER share** your `service_role` key (it has full access to everything)
> - **ONLY use** the `anon` key in your Flutter app
> - **NEVER commit** `.env` file to Git (it's already in `.gitignore`)
> - The `anon` key is safe for client-side apps because RLS (Row Level Security) protects your data

---

## 4. Configure the App

### Step 4.1: Locate Your `.env` File

Your project should already have a `.env` file in the root directory.

**Location**: `D:\vendor_app\.env`

### Step 4.2: Edit `.env` File

1. Open `.env` in any text editor (VS Code, Notepad++, etc.)

2. Replace the placeholder values with your actual Supabase credentials:

   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-actual-anon-key-here
   ```

   **Example:**
   ```env
   SUPABASE_URL=https://abcdefgh.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxhdGluLXRlc3QiLCJyb2xlIjoiYW5vbiIsImF1ZCI6ImJhYzdlNDM4ZTZiMjQ0ODRhOWQ4Zjk2ZTc0NjA3YzZhIiwiaWF0IjoxNjE2NjY5NjczLCJleHAiOjE5MzIyNDU2NzN9.pHxr4F4YFQyVHfEL4pXzM2JK8mJdNM7Gq9X1
   ```

3. **Save** the file

### Step 4.3: Verify Configuration

The app is already configured to read from `.env` file. Check `lib/config/supabase_config.dart`:

```dart
// This loads your .env file automatically
await dotenv.load(fileName: ".env");

// Gets credentials from environment variables
final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
```

✅ **No changes needed** - it's already set up correctly!

---

## 5. Set Up Database

### Step 5.1: Open SQL Editor

1. In your Supabase dashboard, look at the left sidebar
2. Click **"SQL Editor"** icon (looks like a terminal `>_`)
3. You'll see a query editor interface

### Step 5.2: Run the Setup Script

1. Open the **`QUERY.sql`** file in your project:
   - Location: `D:\vendor_app\QUERY.sql`

2. **Select all** the content (Ctrl+A)
3. **Copy** (Ctrl+C)

4. Go back to Supabase SQL Editor
5. **Paste** the SQL (Ctrl+V) into the editor

6. **Click "Run"** button ▶️ (bottom right)
   - Or press **Ctrl+Enter**

7. **Wait for execution** - should complete in 2-5 seconds

### What This Script Does:

✅ Creates **7 tables**:
- `vendors` - Vendor profiles
- `customers` - Customer addresses
- `products` - Product catalog
- `vendor_products` - Vendor-specific pricing & inventory
- `orders` - Order management
- `order_items` - Order line items
- `payments` - Payment tracking

✅ Creates **triggers** for:
- Auto-updating timestamps
- Auto-calculating payment status
- Auto-deducting inventory on delivery

✅ Creates **views** for common queries:
- `orders_full` - Orders with customer details
- `vendor_inventory_status` - Inventory levels
- `order_payments_summary` - Payment history

✅ Sets up **Row Level Security (RLS)** policies

✅ Inserts **sample products** (20L, 10L, 5L water cans)

### Step 5.3: Verify Tables Created

1. In Supabase dashboard, click **"Table Editor"** (grid icon in sidebar)
2. You should see all 7 tables listed:
   ```
   ✅ customers
   ✅ order_items
   ✅ orders
   ✅ payments
   ✅ products
   ✅ vendor_products
   ✅ vendors
   ```

3. Click on any table to see its structure

4. Check `products` table - should have 3 sample products:
   - 20L Water Can
   - 10L Water Can
   - 5L Water Can

---

## 6. Enable Phone Authentication

### Step 6.1: Enable Phone Provider

1. In Supabase dashboard, click **"Authentication"** (user icon in sidebar)
2. Click **"Providers"** tab
3. Find **"Phone"** in the list
4. Click the **toggle switch** to enable it

### Step 6.2: Configure SMS Provider

You need an SMS provider to send OTPs. Here are popular options:

#### Option A: **Twilio** (Most Popular)

1. Go to **https://www.twilio.com**
2. **Sign up** for free account
3. Get your **Account SID** and **Auth Token** from dashboard
4. Go to **Messaging** → **Settings** → **Geography & permissions**
5. Add your country (e.g., India) and enable SMS

6. **Back in Supabase**:
   - In Phone provider settings, select **"Twilio"**
   - Enter:
     - **Account SID**: `your_twilio_account_sid`
     - **Auth Token**: `your_twilio_auth_token`
     - **From Number**: Your Twilio phone number (e.g., `+1234567890`)
   - Click **"Save"**

#### Option B: **MessageBird** (Now called Bird)

1. Go to **https://www.bird.com**
2. Sign up for account
3. Get your **API Key** and **Access Key**
4. Buy a phone number or use sandbox

5. **In Supabase**:
   - Select **"MessageBird"**
   - Enter your API keys
   - Click **"Save"**

#### Option C: **Test Mode** (For Development Only)

If you don't want to configure SMS provider yet, you can use **Test Mode**:

1. In your Flutter app, edit `lib/services/auth_service.dart`
2. Change line 11:
   ```dart
   static const bool _testMode = true;  // Enable test mode
   ```
3. Now any phone number will accept OTP: `123456`

> **⚠️ Warning**: Remember to set `_testMode = false` before production!

### Step 6.3: Create Auth Schema (Optional)

Phone authentication works out-of-the-box with Supabase. The `auth.users` table is automatically created by Supabase.

Your app links to this using:
- User's phone number → `auth.users.phone`
- User ID → `vendors.id` (they match!)

---

## 7. Test the Connection

### Step 7.1: Install Flutter Dependencies

Open terminal/command prompt in your project folder:

```bash
cd D:\vendor_app
flutter pub get
```

You should see:
```
Got dependencies!  X packages have newer versions incompatible...
```

This is normal ✅

### Step 7.2: Run the App

**Option A: Run with device selection**

1. List available devices:
   ```bash
   flutter devices
   ```

2. Run on specific device:
   ```bash
   flutter run -d <device-id>
   ```

**Option B: Run and let Flutter choose**

```bash
flutter run
```

**Option C: Run on specific platform**

```bash
# Android
flutter run -d android

# Windows Desktop
flutter run -d windows

# Web
flutter run -d edge
```

### Step 7.3: What You Should See

1. **App launches** on your device/emulator
2. **Login screen** appears:
   - Phone number input field
   - "Send OTP" button

3. **Enter phone number**:
   - Format with country code: `+919876543210`
   - Click **"Send OTP"**

4. **OTP Screen** appears:
   - 6-digit OTP input
   - If **Test Mode**: Enter `123456`
   - If **Production**: Enter OTP sent to your phone

5. **Profile Setup Screen**:
   - Enter your details:
     - Name: `Your Name`
     - Business Name: `My Water Delivery`
     - Address: `Your Business Address`
   - Click **"Create Profile"**

6. **Home Screen** appears:
   - Bottom navigation with 4 tabs
   - Welcome message
   - Empty order lists (normal for first time)

### Step 7.4: Verify Data in Supabase

1. Go to Supabase Dashboard
2. Click **"Table Editor"**
3. Open the **`vendors`** table
4. You should see **your vendor profile**!

✅ **Congratulations! Your app is connected to Supabase!**

---

## 8. Troubleshooting

### Issue 1: "Supabase credentials not found"

**Error Message:**
```
Exception: Supabase credentials not found. Please check your .env file.
```

**Solutions:**

1. Check `.env` file exists:
   ```bash
   # In PowerShell
   dir .env

   # In CMD
   dir .env

   # Should see: .env
   ```

2. Check credentials are correct:
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-full-anon-key
   ```
   - No extra spaces
   - No quotes around values
   - `https://` prefix present in URL

3. Check file is in correct location:
   - Should be at `D:\vendor_app\.env`
   - Same folder as `pubspec.yaml`

---

### Issue 2: "Permission denied" or "Row Level Security"

**Error Message:**
```
Error: Permission denied
```

**Solutions:**

1. Make sure you ran the `QUERY.sql` script
2. Check RLS policies exist:
   - Go to **Authentication** → **Policies** in Supabase
   - You should see policies for all tables
3. If missing, re-run `QUERY.sql`

---

### Issue 3: "No such table" errors

**Error Message:**
```
Error: relation "public.vendors" does not exist
```

**Solutions:**

1. Verify tables exist in Supabase:
   - Go to **Table Editor**
   - Check if all 7 tables are listed

2. If tables are missing:
   - Go to **SQL Editor**
   - Re-run the `QUERY.sql` script
   - Check for any error messages

---

### Issue 4: OTP Not Sending

**Error:**
OTP never arrives on phone

**Solutions:**

1. **Check SMS provider configuration**:
   - Go to **Authentication** → **Providers** → **Phone**
   - Verify API keys are correct
   - Check sender ID is valid

2. **Check phone number format**:
   - Must include country code: `+91XXXXXXXXXX`
   - No spaces or dashes

3. **Check SMS provider credits**:
   - Log in to your SMS provider dashboard
   - Verify you have credits/balance

4. **Use Test Mode** for development:
   ```dart
   // In lib/services/auth_service.dart
   static const bool _testMode = true;  // Use 123456 as OTP
   ```

---

### Issue 5: "Connection refused" or Network Errors

**Error Message:**
```
Failed host lookup: 'xxxxxxxxxxxxx.supabase.co'
SocketException: Connection refused
```

**Solutions:**

1. Check internet connection
2. Verify Supabase URL is correct:
   - Copy from Supabase Dashboard → Settings → API
   - Should be: `https://xxxxx.supabase.co`
3. Check if Supabase is down:
   - Visit https://status.supabase.com
4. Try accessing Supabase dashboard in browser

---

### Issue 6: App Crashes on Launch

**Error:**
App crashes immediately after launching

**Solutions:**

1. Check Flutter logs:
   ```bash
   flutter run --verbose
   ```

2. Common issues:
   - Missing `.env` file
   - Invalid Supabase URL
   - Network not available

3. Try running on different platform:
   ```bash
   flutter run -d chrome
   ```

---

### Issue 7: Database Migration Errors

**When upgrading from v1.0 to v2.0**

**Solutions:**

1. Use the migration script in `DATABASE_SCHEMA.md` (Migration 1 section)
2. Or start fresh:
   - Drop all tables
   - Re-run `QUERY.sql`
   - **Warning**: This deletes all data!

---

## 9. Next Steps

### ✅ After Successful Connection

1. **Create Your Vendor Profile**
   - Enter your business details
   - Upload logo (optional)

2. **Add Products to Inventory**
   - Go to **Inventory** tab
   - Add products with pricing:
     - 20L Water Can - ₹70
     - 10L Water Can - ₹40
     - 5L Water Can - ₹25
   - Set initial stock levels

3. **Test Creating Orders**
   - Since you don't have a customer app yet, you can:
     - Manually insert test orders via Supabase SQL Editor
     - Or wait for customer orders to come in

4. **Explore Supabase Dashboard**
   - **Table Editor**: View and edit data
   - **SQL Editor**: Run custom queries
   - **Database Logs**: Monitor database activity
   - **Authentication**: Manage users

---

## 10. Production Checklist

Before going live with real customers:

### Security

- [ ] Set `_testMode = false` in `auth_service.dart`
- [ ] Set `_useDummyData = false` in `order_service.dart`
- [ ] Verify RLS policies are active
- [ ] Remove any test data from database
- [ ] Use real SMS provider (not test mode)

### Configuration

- [ ] Update app name and package name
- [ ] Add app icon (already exists in `assets/icons/app_icon.png`)
- [ ] Configure push notifications (FCM)
- [ ] Set up proper error logging

### Database

- [ ] Back up database regularly
- [ ] Set up database replication (optional)
- [ ] Configure database hooks (if needed)
- [ ] Monitor database size (500 MB limit on free tier)

### Testing

- [ ] Test full flow: login → profile → order → delivery → payment
- [ ] Test with multiple vendors (multi-tenancy)
- [ ] Test inventory deduction
- [ ] Test partial payments
- [ ] Test on real devices, not just emulator

---

## 11. Useful Resources

### Official Documentation

- **Supabase Docs**: https://supabase.com/docs
- **Flutter Docs**: https://flutter.dev/docs
- **Supabase Flutter**: https://supabase.com/docs/guides/getting-started/flutter

### Community

- **Supabase Discord**: https://supabase.com/discord
- **Flutter Community**: https://flutter.dev/community
- **Stack Overflow**: Tag questions with `supabase` and `flutter`

### Video Tutorials

- Search YouTube: "Supabase Flutter tutorial"
- Official Supabase YouTube channel

---

## 12. Quick Reference

### Important File Locations

```
D:\vendor_app\
├── .env                          # Supabase credentials
├── QUERY.sql                     # Database setup script
├── DATABASE_SCHEMA.md            # Full database documentation
├── lib/
│   ├── config/
│   │   └── supabase_config.dart  # Supabase initialization
│   ├── services/
│   │   ├── auth_service.dart     # Test mode flag (line 11)
│   │   └── order_service.dart    # Dummy data flag (line 12)
│   └── models/
│       └── order.dart            # Data models
└── pubspec.yaml                  # Flutter dependencies
```

### Important Supabase Dashboard URLs

After logging in:

- **Home**: `https://supabase.com/dashboard/project/xxxxx`
- **SQL Editor**: `https://supabase.com/dashboard/project/xxxxx/sql/new`
- **Table Editor**: `https://supabase.com/dashboard/project/xxxxx/editor`
- **API Settings**: `https://supabase.com/dashboard/project/xxxxx/settings/api`
- **Authentication**: `https://supabase.com/dashboard/project/xxxxx/auth/providers`

Replace `xxxxx` with your actual project reference ID.

### Common Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d emulator-5554

# Clean build
flutter clean
flutter pub get

# Analyze code
flutter analyze

# Build APK
flutter build apk --release

# Check devices
flutter devices
```

---

## Need Help?

If you're still stuck after following this guide:

1. **Check the error message** - Read it carefully, it usually tells you what's wrong
2. **Check Supabase logs** - Dashboard → Database → Logs
3. **Check Flutter logs** - Run `flutter run --verbose`
4. **Google the error** - Someone likely had the same issue
5. **Ask in community forums** - Supabase Discord or Stack Overflow

---

**Good luck with your Can Can Vendor app! 🚀**

*For questions specific to this codebase, check `CLAUDE.md` in the project root.*
