import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Vendor Service - Handles vendor profile CRUD operations
class VendorService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  /// Create vendor profile (first-time setup)
  Future<Map<String, dynamic>> createVendorProfile({
    required String phone,
    required String name,
    required String businessName,
    required String address,
  }) async {
    try {
      // Add +91 prefix if not present
      final fullPhone = phone.startsWith('+91') ? phone : '+91$phone';

      // Generate a proper UUID for the vendor
      final vendorId = SupabaseConfig.currentVendorId ?? _uuid.v4();

      AppLogger.d('Creating vendor profile: $name ($fullPhone) with ID: $vendorId');

      // Check if vendor already exists by phone
      final existing = await _supabase
          .from('vendors')
          .select()
          .eq('phone', fullPhone)
          .maybeSingle();

      if (existing != null) {
        AppLogger.w('Vendor already exists');
        return {
          'success': true, // Return success since profile exists
          'message': 'Profile already exists',
          'vendorId': existing['id'],
        };
      }

      // Insert new vendor with proper UUID
      await _supabase.from('vendors').insert({
        'id': vendorId,
        'phone': fullPhone,
        'name': name,
        'business_name': businessName,
        'address': address,
        'is_active': true,
      });

      AppLogger.i('Vendor profile created successfully: $vendorId');

      return {
        'success': true,
        'message': 'Profile created successfully',
        'vendorId': vendorId,
      };
    } catch (e) {
      AppLogger.e('Error creating vendor profile: $e (${e.runtimeType})');
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
      AppLogger.e('Error fetching vendor profile: $e');
      return null;
    }
  }

  /// Update vendor profile
  Future<Map<String, dynamic>> updateVendorProfile({
    String? name,
    String? businessName,
    String? address,
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
      AppLogger.e('Error updating vendor profile: $e');
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
      AppLogger.e('Error setting vacation mode: $e');
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

      // Get total cans and earnings for the day
      final orders = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('vendor_id', vendorId)
          .eq('delivery_date', dateStr)
          .eq('status', 'pending');

      int totalCans = 0;
      double totalEarnings = 0.0;

      for (final order in orders) {
        // Get order items count
        final items = await _supabase
            .from('order_items')
            .select('quantity')
            .eq('order_id', order['id']);

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
      AppLogger.e('Error fetching daily summary: $e');
      return {'cansToDeliver': 0, 'earnings': 0.0};
    }
  }
}
