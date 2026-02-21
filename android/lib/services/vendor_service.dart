import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Vendor Service - Handles vendor data operations with Supabase
class VendorService {
  final _supabase = SupabaseConfig.client;

  /// Get current vendor profile from Supabase
  Future<Map<String, dynamic>?> getVendorProfile() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        AppLogger.w('No vendor ID found');
        return null;
      }

      AppLogger.d('Fetching vendor profile for: $vendorId');

      final response = await _supabase
          .from('vendors')
          .select()
          .eq('id', vendorId)
          .maybeSingle();

      if (response == null) {
        AppLogger.w('Vendor not found: $vendorId');
        return null;
      }

      AppLogger.i('Vendor profile fetched successfully');
      return {
        'id': response['id'],
        'name': response['owner_name'] ?? response['name'],
        'business_name': response['business_name'],
        'phone': response['phone'],
        'email': response['email'],
        'address': response['address'],
        'flat_number': response['flat_number'],
        'floor': response['floor'],
        'building_name': response['building_name'],
        'landmark': response['landmark'],
        'city': response['city'],
        'state': response['state'],
        'pincode': response['pincode'],
        'latitude': response['latitude'],
        'longitude': response['longitude'],
        'is_active': response['is_active'],
        'is_verified': response['is_verified'],
        'is_on_vacation': response['is_on_vacation'],
        'vacation_reason': response['vacation_reason'],
        'vacation_end_date': response['vacation_end_date'],
        'business_hours': response['business_hours'],
        'rating': response['rating'],
        'total_orders': response['total_orders'],
        'completed_orders': response['completed_orders'],
        'cancelled_orders': response['cancelled_orders'],
        'average_delivery_time': response['average_delivery_time'],
        'total_revenue': response['total_revenue'],
        'commission_rate': response['commission_rate'],
        'wallet_balance': response['wallet_balance'],
        'service_areas': response['service_areas'],
      };
    } catch (e) {
      AppLogger.e('Error fetching vendor profile: $e');
      return null;
    }
  }

  /// Create new vendor profile
  Future<Map<String, dynamic>> createVendorProfile({
    required String phone,
    required String name,
    required String businessName,
    required String address,
  }) async {
    try {
      AppLogger.d('Creating vendor profile for: $phone');

      final vendorData = {
        'phone': phone,
        'owner_name': name,
        'business_name': businessName,
        'address': address,
        'is_active': true,
        'is_verified': false,
        'is_on_vacation': false,
        'rating': 0.0,
        'total_orders': 0,
        'completed_orders': 0,
        'cancelled_orders': 0,
        'total_revenue': 0.0,
        'commission_rate': 0.15,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('vendors')
          .insert(vendorData)
          .select('id')
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'message': 'Failed to create vendor profile',
        };
      }

      AppLogger.i('Vendor profile created successfully: ${response['id']}');
      return {
        'success': true,
        'message': 'Profile created successfully',
        'vendorId': response['id'],
      };
    } catch (e) {
      AppLogger.e('Error creating vendor profile: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Update vendor profile
  Future<Map<String, dynamic>> updateVendorProfile({
    required String name,
    required String businessName,
    required String address,
    String? flatNumber,
    String? floor,
    String? buildingName,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Updating vendor profile: $vendorId');

      final updateData = <String, dynamic>{
        'owner_name': name,
        'business_name': businessName,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (flatNumber != null) updateData['flat_number'] = flatNumber;
      if (floor != null) updateData['floor'] = floor;
      if (buildingName != null) updateData['building_name'] = buildingName;
      if (landmark != null) updateData['landmark'] = landmark;
      if (city != null) updateData['city'] = city;
      if (state != null) updateData['state'] = state;
      if (pincode != null) updateData['pincode'] = pincode;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;

      final error = await _supabase
          .from('vendors')
          .update(updateData)
          .eq('id', vendorId);

      if (error != null) {
        AppLogger.e('Error updating vendor profile: $error');
        return {
          'success': false,
          'message': 'Failed to update profile',
          'error': error.toString(),
        };
      }

      AppLogger.i('Vendor profile updated successfully');
      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } catch (e) {
      AppLogger.e('Error updating vendor profile: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Update business hours
  Future<Map<String, dynamic>> updateBusinessHours(Map<String, dynamic> businessHours) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Updating business hours for vendor: $vendorId');

      final error = await _supabase
          .from('vendors')
          .update({
            'business_hours': businessHours,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      if (error != null) {
        AppLogger.e('Error updating business hours: $error');
        return {
          'success': false,
          'message': 'Failed to update business hours',
          'error': error.toString(),
        };
      }

      AppLogger.i('Business hours updated successfully');
      return {
        'success': true,
        'message': 'Business hours updated successfully',
      };
    } catch (e) {
      AppLogger.e('Error updating business hours: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Toggle vacation mode
  Future<Map<String, dynamic>> toggleVacationMode({
    required bool isOnVacation,
    String? reason,
    DateTime? endDate,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Toggling vacation mode for vendor: $vendorId');

      final error = await _supabase
          .from('vendors')
          .update({
            'is_on_vacation': isOnVacation,
            'vacation_reason': reason,
            'vacation_end_date': endDate?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      if (error != null) {
        AppLogger.e('Error toggling vacation mode: $error');
        return {
          'success': false,
          'message': 'Failed to update vacation mode',
          'error': error.toString(),
        };
      }

      AppLogger.i('Vacation mode updated successfully');
      return {
        'success': true,
        'message': isOnVacation
            ? 'Vacation mode enabled'
            : 'Vacation mode disabled',
      };
    } catch (e) {
      AppLogger.e('Error toggling vacation mode: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Get wallet balance
  Future<Map<String, dynamic>?> getWalletBalance() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return null;
      }

      AppLogger.d('Fetching wallet balance for vendor: $vendorId');

      final response = await _supabase
          .from('vendor_wallets')
          .select()
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return {
        'balance': response['balance'] ?? 0.0,
        'pending_balance': response['pending_balance'] ?? 0.0,
      };
    } catch (e) {
      AppLogger.e('Error fetching wallet balance: $e');
      return null;
    }
  }
}
