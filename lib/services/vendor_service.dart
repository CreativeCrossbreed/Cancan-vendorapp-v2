import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'vendor_data_service.dart';

/// Vendor Service - Handles vendor profile CRUD operations
class VendorService {
  final _supabase = SupabaseConfig.client;

  /// Create vendor profile (first-time setup)
  Future<Map<String, dynamic>> createVendorProfile({
    required String phone,
    required String name,
    required String businessName,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Add +91 prefix if not present
      final fullPhone = phone.startsWith('+91') ? phone : '+91$phone';

      debugPrint('📝 Creating vendor profile...');
      debugPrint('   Phone: $fullPhone');
      debugPrint('   Name: $name');
      debugPrint('   Business: $businessName');
      debugPrint('   Address: $address');

      // Check if vendor already exists by phone
      final existing = await _supabase
          .from('vendors')
          .select()
          .eq('phone', fullPhone)
          .maybeSingle();

      if (existing != null) {
        debugPrint('⚠️ Vendor already exists with phone: $fullPhone');
        debugPrint('📋 Existing vendor ID: ${existing['id']}');
        debugPrint('📋 Existing vendor name: ${existing['name']}');

        // Update the existing vendor's details
        final updated = await _supabase
            .from('vendors')
            .update({
              'name': name,
              'business_name': businessName,
              'address': address,
              'latitude': latitude,
              'longitude': longitude,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id'])
            .select()
            .single();

        debugPrint('✅ Existing vendor profile updated: ${updated['id']}');

        return {
          'success': true,
          'message': 'Profile updated successfully',
          'vendorId': updated['id'],
          'updated': true,
        };
      }

      // Use the authenticated user ID (auth.uid()) as vendor ID
      // This ensures RLS policies work correctly since they check id = auth.uid()
      final vendorId = SupabaseConfig.currentVendorId;

      if (vendorId == null) {
        debugPrint('❌ No authenticated user found');
        return {
          'success': false,
          'message': 'User not authenticated. Please login again.',
        };
      }

      // Real vendors table has no `test_mode` column — RLS is scoped via
      // `auth.uid() = id` directly (see Model A), so no extra flag is needed
      // here regardless of whether this came from a test-mode sign-in.
      await _supabase.from('vendors').insert({
        'id': vendorId,
        'phone': fullPhone,
        'name': name,
        'business_name': businessName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': true,
      });

      debugPrint('✅ Vendor profile created successfully: $vendorId');

      return {
        'success': true,
        'message': 'Profile created successfully',
        'vendorId': vendorId,
        'created': true,
      };
    } catch (e) {
      debugPrint('❌ Error creating vendor profile: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      return {
        'success': false,
        'message': 'Failed to create profile: ${e.toString()}',
      };
    }
  }

  /// Get vendor profile
  Future<Map<String, dynamic>?> getVendorProfile() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;

      if (vendorId == null) return null;

      final data =
          await _supabase.from('vendors').select().eq('id', vendorId).single();

      return data;
    } catch (e) {
      debugPrint('Error fetching vendor profile: $e');
      return null;
    }
  }

  /// Update vendor profile
  Future<Map<String, dynamic>> updateVendorProfile({
    String? name,
    String? businessName,
    String? address,
    double? latitude,
    double? longitude,
    int? maxDailyDeliveries,
    int? maxDailyCans,
    Map<String, dynamic>? workingHours,
    List<String>? workingDays,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;

      if (vendorId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (businessName != null) updates['business_name'] = businessName;
      if (address != null) updates['address'] = address;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (maxDailyDeliveries != null) {
        updates['max_daily_deliveries'] = maxDailyDeliveries;
      }
      if (maxDailyCans != null) updates['max_daily_cans'] = maxDailyCans;
      if (workingHours != null) updates['working_hours'] = workingHours;
      if (workingDays != null) updates['working_days'] = workingDays;

      await _supabase.from('vendors').update(updates).eq('id', vendorId);

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } catch (e) {
      debugPrint('Error updating vendor profile: $e');
      return {
        'success': false,
        'message': 'Failed to update profile.',
      };
    }
  }

  /// Save payout (bank or UPI) details used by the Cashfree payout engine.
  ///
  /// [method] is 'bank' or 'upi'. Only the fields for the chosen method are
  /// stored; the other set is nulled so the beneficiary transfer mode is
  /// unambiguous. Any existing `cf_beneficiary_id` is cleared so the backend
  /// re-registers the beneficiary with the new details on the next payout.
  Future<Map<String, dynamic>> updatePayoutDetails({
    required String method,
    required String holderName,
    String? accountNumber,
    String? ifsc,
    String? vpa,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final updates = <String, dynamic>{
        'bank_account_holder_name': holderName.trim(),
        'cf_beneficiary_id': null, // force re-registration with new details
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (method == 'bank') {
        updates['bank_account_number'] = accountNumber?.trim();
        updates['bank_ifsc'] = ifsc?.trim().toUpperCase();
        updates['payout_vpa'] = null;
      } else {
        updates['payout_vpa'] = vpa?.trim();
        updates['bank_account_number'] = null;
        updates['bank_ifsc'] = null;
      }

      await _supabase.from('vendors').update(updates).eq('id', vendorId);
      await VendorDataService.clearCache();

      return {'success': true, 'message': 'Payout details saved'};
    } catch (e) {
      debugPrint('Error saving payout details: $e');
      return {'success': false, 'message': 'Failed to save payout details.'};
    }
  }

  /// Set vacation mode
  Future<Map<String, dynamic>> setVacationMode({
    required bool isOnVacation,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;

      if (vendorId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      await _supabase.from('vendors').update({
        'is_on_vacation': isOnVacation,
        'vacation_start_date': startDate?.toIso8601String(),
        'vacation_end_date': endDate?.toIso8601String(),
      }).eq('id', vendorId);

      return {
        'success': true,
        'message':
            isOnVacation ? 'Vacation mode enabled' : 'Vacation mode disabled',
      };
    } catch (e) {
      debugPrint('Error setting vacation mode: $e');
      return {
        'success': false,
        'message': 'Failed to update vacation mode.',
      };
    }
  }

  /// Get daily summary
  Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;

      if (vendorId == null) return {'cansToDeliver': 0, 'earnings': 0.0};

      final dateStr = date.toIso8601String().split('T')[0];

      // Get total cans and earnings for the day in one query.
      final orders = await _supabase
          .from('orders')
          .select('total_amount, order_items(quantity)')
          .eq('vendor_id', vendorId)
          .eq('delivery_date', dateStr)
          .eq('status', 'pending');

      int totalCans = 0;
      double totalEarnings = 0.0;

      for (final order in orders) {
        final items = (order['order_items'] as List<dynamic>? ?? []);
        for (final item in items) {
          totalCans += (item['quantity'] as int);
        }

        totalEarnings += (order['total_amount'] as num).toDouble();
      }

      return {
        'cansToDeliver': totalCans,
        'earnings': totalEarnings,
      };
    } catch (e) {
      debugPrint('Error fetching daily summary: $e');
      return {'cansToDeliver': 0, 'earnings': 0.0};
    }
  }

  /// Vendor is order-ready only when location exists and at least
  /// one active vendor_product has stock > 0.
  Future<Map<String, dynamic>> getVendorReadinessStatus() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'isReady': false,
          'missingLocation': true,
          'missingInventory': true,
          'message': 'Vendor is not authenticated.',
        };
      }

      final profile = await _supabase
          .from('vendors')
          .select('latitude, longitude')
          .eq('id', vendorId)
          .maybeSingle();

      final hasLocation = profile != null &&
          profile['latitude'] != null &&
          profile['longitude'] != null;

      final stocked = await _supabase
          .from('vendor_products')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .gt('current_stock', 0)
          .limit(1);

      final hasInventory = stocked.isNotEmpty;
      final isReady = hasLocation && hasInventory;

      String message;
      if (isReady) {
        message = 'Vendor is ready to receive orders.';
      } else if (!hasLocation && !hasInventory) {
        message = 'Add business location and stock to start receiving orders.';
      } else if (!hasLocation) {
        message = 'Add business location (latitude/longitude) to receive nearby orders.';
      } else {
        message = 'Add at least one active in-stock product to receive orders.';
      }

      return {
        'isReady': isReady,
        'missingLocation': !hasLocation,
        'missingInventory': !hasInventory,
        'message': message,
      };
    } catch (e) {
      debugPrint('Error checking vendor readiness: $e');
      return {
        'isReady': false,
        'missingLocation': true,
        'missingInventory': true,
        'message': 'Unable to verify readiness right now.',
      };
    }
  }
}
