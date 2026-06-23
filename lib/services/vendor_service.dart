import '../config/supabase_config.dart';
import 'auth_service.dart' as auth;

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

      print('📝 Creating vendor profile...');
      print('   Phone: $fullPhone');
      print('   Name: $name');
      print('   Business: $businessName');
      print('   Address: $address');

      // Check if vendor already exists by phone
      final existing = await _supabase
          .from('vendors')
          .select()
          .eq('phone', fullPhone)
          .maybeSingle();

      if (existing != null) {
        print('⚠️ Vendor already exists with phone: $fullPhone');
        print('📋 Existing vendor ID: ${existing['id']}');
        print('📋 Existing vendor name: ${existing['name']}');

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

        print('✅ Existing vendor profile updated: ${updated['id']}');

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
        print('❌ No authenticated user found');
        return {
          'success': false,
          'message': 'User not authenticated. Please login again.',
        };
      }

      // Check if we're in test mode
      final authService = auth.AuthService();
      final isTestMode = authService.isInTestMode;

      await _supabase.from('vendors').insert({
        'id': vendorId,
        'phone': fullPhone,
        'name': name,
        'business_name': businessName,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': true,
        'test_mode': isTestMode, // Mark test mode vendors for RLS policies
      });

      if (isTestMode) {
        print('🧪 Creating test mode vendor profile');
      }

      print('✅ Vendor profile created successfully: $vendorId');

      return {
        'success': true,
        'message': 'Profile created successfully',
        'vendorId': vendorId,
        'created': true,
      };
    } catch (e) {
      print('❌ Error creating vendor profile: $e');
      print('   Error type: ${e.runtimeType}');
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
      print('Error fetching vendor profile: $e');
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
      print('Error updating vendor profile: $e');
      return {
        'success': false,
        'message': 'Failed to update profile.',
      };
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
      print('Error setting vacation mode: $e');
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
      print('Error fetching daily summary: $e');
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
      print('Error checking vendor readiness: $e');
      return {
        'isReady': false,
        'missingLocation': true,
        'missingInventory': true,
        'message': 'Unable to verify readiness right now.',
      };
    }
  }
}
