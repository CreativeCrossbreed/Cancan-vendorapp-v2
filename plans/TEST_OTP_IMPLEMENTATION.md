# Implementation Plan: Test OTP (000000) Feature

## Overview

Modify the authentication system to support a **test OTP** (`000000`) that bypasses real SMS verification while keeping the real OTP flow intact for production.

## How It Works

```
┌─────────────────┐
│  User enters   │
│  phone number  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Send OTP      │
│  (real SMS)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  User enters   │
│  OTP code      │
└────────┬────────┘
         │
         ▼
    ┌────┴────┐
    │ OTP is   │
    │ 000000?  │
    └────┬────┘
         │
    ┌────┴────┐
    │         │
   YES       NO
    │         │
    ▼         ▼
┌───────┐ ┌──────────┐
│ Test  │ │ Real     │
│ Mode  │ │ Verify   │
│ Flow  │ │ with     │
│       │ │ Supabase │
└───┬───┘ └─────┬────┘
    │           │
    └─────┬─────┘
          │
          ▼
   ┌──────────────┐
   │ Create/Load │
   │ Vendor      │
   │ Profile     │
   └──────────────┘
```

## Changes Required

### 1. Modify `lib/services/auth_service.dart`

#### Current Code (lines 10-12):
```dart
// TEST MODE FLAG - Set to false when ready for production
static const bool _testMode = false;
static const String _testOTP = '123456'; // Test OTP for development
```

#### New Code:
```dart
// Test OTP for development - bypasses real SMS verification
static const String _testOTP = '000000';
```

#### Modify `sendOTP()` method (lines 14-52):

Keep the real OTP flow. The test OTP check only happens during verification.

#### Modify `verifyOTP()` method (lines 54-153):

Add test OTP check at the beginning:

```dart
Future<Map<String, dynamic>> verifyOTP({
  required String phoneNumber,
  required String otp,
}) async {
  // Check for test OTP first (bypasses real SMS)
  if (otp == _testOTP) {
    print('🧪 TEST MODE: Using test OTP for +91$phoneNumber');

    await Future.delayed(const Duration(seconds: 1));

    // Create a test vendor ID based on phone number
    final testVendorId = 'test_vendor_${phoneNumber.replaceAll(RegExp(r'\D'), '')}';

    // Check if vendor profile exists in database
    try {
      final vendorData = await _supabase
          .from('vendors')
          .select()
          .eq('phone', '+91$phoneNumber')
          .maybeSingle();

      print('🧪 TEST MODE: Has profile: ${vendorData != null}');

      final vendorId = vendorData?['id'] ?? testVendorId;

      // Persist session locally
      await SessionService.saveSession(
        vendorId: vendorId,
        vendorPhone: '+91$phoneNumber',
        hasProfile: vendorData != null,
      );

      return {
        'success': true,
        'message': 'Login successful',
        'hasProfile': vendorData != null,
        'testMode': true,
        'vendorId': vendorId,
      };
    } catch (e) {
      print('🧪 TEST MODE: Error checking profile: $e');
      return {
        'success': true,
        'message': 'Login successful',
        'hasProfile': false,
        'testMode': true,
        'vendorId': testVendorId,
      };
    }
  }

  // PRODUCTION MODE: Real OTP verification via Supabase
  try {
    final fullNumber =
        phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

    final response = await _supabase.auth.verifyOTP(
      type: OtpType.sms,
      phone: fullNumber,
      token: otp,
    );

    if (response.user != null) {
      final vendorData = await _supabase
          .from('vendors')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      return {
        'success': true,
        'message': 'Login successful',
        'hasProfile': vendorData != null,
        'user': response.user,
      };
    }

    return {
      'success': false,
      'message': 'Invalid OTP',
    };
  } catch (e) {
    print('Error verifying OTP: $e');
    return {
      'success': false,
      'message': 'Verification failed. Please try again.',
    };
  }
}
```

### 2. Update `lib/screens/auth/otp_screen.dart`

Modify the error message when invalid OTP is entered (around line 70):

```dart
} else {
  _showError(
    result['message'] ?? 'Invalid OTP. For testing, use: 000000'
  );
}
```

### 3. Update `lib/screens/auth/login_screen.dart`

Update the test mode indicator (lines 182-212):

```dart
// TEST MODE INDICATOR
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppTheme.warningOrange.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: AppTheme.warningOrange.withValues(alpha: 0.5),
    ),
  ),
  child: Row(
    children: [
      const Icon(
        Icons.science_outlined,
        color: AppTheme.warningOrange,
        size: 20,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          'DEV: Use OTP 000000 for testing',
          style:
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w600,
                  ),
        ),
      ),
    ],
  ),
),
```

## Testing Workflow

### Step 1: Test with Test OTP (000000)

| Action | Expected Result |
|--------|----------------|
| Enter phone: `9876543210` | Phone accepted |
| Click "Send OTP" | OTP screen appears |
| Enter OTP: `000000` | Login successful |
| If new vendor | Profile setup screen |
| If existing vendor | Home screen |

### Step 2: Verify Data in Supabase

After creating profile:
1. Go to Supabase Dashboard → Table Editor
2. Open `vendors` table
3. You should see your vendor record with phone number

### Step 3: Add Test Products

Use SQL Editor to add products:

```sql
-- Get your vendor_id first
SELECT id, phone FROM vendors;

-- Insert products for your vendor
INSERT INTO vendor_products (vendor_id, product_id, selling_price, deposit_amount, current_stock, low_stock_threshold)
SELECT 
    'your-vendor-id-here'::uuid,
    p.id,
    70.00,
    0.00,
    50,
    10
FROM products p
WHERE p.name = '20L Water Can';

INSERT INTO vendor_products (vendor_id, product_id, selling_price, deposit_amount, current_stock, low_stock_threshold)
SELECT 
    'your-vendor-id-here'::uuid,
    p.id,
    40.00,
    0.00,
    50,
    10
FROM products p
WHERE p.name = '10L Water Can';
```

### Step 4: Create Test Orders

```sql
-- Insert test customer
INSERT INTO customers (name, phone, address, flat_number, floor, building_name)
VALUES ('Test Customer', '+919876543210', '123 Test Street', 'A-101', '1', 'Test Building');

-- Insert test order
INSERT INTO orders (order_number, vendor_id, customer_id, delivery_date, time_slot, total_amount, status, payment_status)
VALUES (
    '#1001',
    'your-vendor-id-here'::uuid,
    (SELECT id FROM customers WHERE phone = '+919876543210' LIMIT 1),
    CURRENT_DATE,
    '8:00 AM - 10:00 AM',
    140.00,
    'pending',
    'unpaid'
);

-- Insert order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal)
SELECT 
    (SELECT id FROM orders ORDER BY created_at DESC LIMIT 1),
    p.id,
    2,
    70.00,
    140.00
FROM products p
WHERE p.name = '20L Water Can';
```

## Production Checklist

Before going live:

- [ ] Remove or hide the "DEV: Use OTP 000000" indicator
- [ ] Consider removing test OTP check entirely or require environment variable
- [ ] Test with real SMS provider
- [ ] Verify RLS policies are active
- [ ] Remove all test data from database

## Alternative: Environment-Based Test OTP

For better security, make test OTP only available in development:

```dart
// In lib/services/auth_service.dart
static String get _testOTP {
  const isDev = bool.fromEnvironment('dart.vm.product') == false;
  return isDev ? '000000' : '';
}
```

Then run app in debug mode for testing, release mode for production.

## Summary

| Feature | How It Works |
|---------|--------------|
| **Test OTP** | Enter `000000` to bypass SMS verification |
| **Real OTP** | Enter actual SMS code from Supabase |
| **Profile Flow** | Same for both - create or load vendor profile |
| **Data Storage** | All data saved to Supabase normally |

## Benefits

1. **No SMS costs** during development
2. **Real OTP flow** kept intact for production
3. **Easy testing** - just enter `000000`
4. **Full workflow** - profile setup, inventory, orders all work
5. **Flexible** - can test with real OTP when needed
