import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Customer Service - Handles customer data operations with Supabase
class CustomerService {
  final _supabase = SupabaseConfig.client;

  /// Get all customers for current vendor
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        AppLogger.w('No vendor ID found');
        return [];
      }

      AppLogger.d('Fetching all customers for vendor: $vendorId');

      final response = await _supabase
          .from('customers')
          .select('''
            id,
            vendor_id,
            name,
            phone,
            address,
            flat_number,
            floor,
            building_name,
            landmark,
            city,
            state,
            pincode,
            total_orders,
            total_spent,
            average_order_value,
            last_order_at
          ''')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);

      AppLogger.i('Fetched ${response.length} customers');

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      AppLogger.e('Error fetching customers: $e');
      return [];
    }
  }

  /// Get customer by ID
  Future<Map<String, dynamic>?> getCustomerById(String customerId) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return null;
      }

      AppLogger.d('Fetching customer: $customerId');

      final response = await _supabase
          .from('customers')
          .select()
          .eq('id', customerId)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('Error fetching customer: $e');
      return null;
    }
  }

  /// Search customers by name or phone
  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return [];
      }

      AppLogger.d('Searching customers for vendor: $vendorId, query: $query');

      final searchTerm = query.toLowerCase().trim();

      final response = await _supabase
          .from('customers')
          .select('''
            id,
            vendor_id,
            name,
            phone,
            address,
            flat_number,
            floor,
            building_name,
            total_orders,
            total_spent,
            average_order_value,
            last_order_at
          ''')
          .eq('vendor_id', vendorId)
          .or('name.ilike.%$searchTerm%,phone.ilike.%$searchTerm%')
          .order('total_orders', ascending: false)
          .limit(20);

      AppLogger.i('Found ${response.length} customers matching search');

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      AppLogger.e('Error searching customers: $e');
      return [];
    }
  }

  /// Get customer insights/analytics
  Future<Map<String, dynamic>> getCustomerInsights() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'totalCustomers': 0,
          'totalRevenue': 0.0,
          'avgCustomerValue': 0.0,
          'topCustomers': [],
        };
      }

      AppLogger.d('Fetching customer insights for vendor: $vendorId');

      // Get total customers
      final customersResponse = await _supabase
          .from('customers')
          .select('total_orders, total_spent')
          .eq('vendor_id', vendorId);

      final customers = customersResponse as List;

      // Calculate metrics
      final totalCustomers = customers.length;
      final totalRevenue = customers.fold<double>(
          0.0, (sum, c) => sum + (c['total_spent'] as num? ?? 0.0).toDouble());
      final avgCustomerValue = totalCustomers > 0 ? totalRevenue / totalCustomers : 0.0;

      // Get top 5 customers by orders
      final topCustomersResponse = await _supabase
          .from('customers')
          .select('id, name, phone, total_orders, total_spent, last_order_at')
          .eq('vendor_id', vendorId)
          .order('total_orders', ascending: false)
          .limit(5);

      final topCustomers = (topCustomersResponse as List).map((c) => {
            'customerId': c['id'],
            'orderCount': c['total_orders'] ?? 0,
            'totalSpent': c['total_spent'] ?? 0.0,
          }).toList();

      return {
        'totalCustomers': totalCustomers,
        'totalRevenue': totalRevenue,
        'avgCustomerValue': avgCustomerValue,
        'topCustomers': topCustomers,
      };
    } catch (e) {
      AppLogger.e('Error fetching customer insights: $e');
      return {
        'totalCustomers': 0,
        'totalRevenue': 0.0,
        'avgCustomerValue': 0.0,
        'topCustomers': [],
      };
    }
  }

  /// Create or update customer
  Future<Map<String, dynamic>> upsertCustomer({
    required String customerId,
    required String name,
    required String phone,
    required String address,
    String? flatNumber,
    String? floor,
    String? buildingName,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Upserting customer: $customerId');

      final customerData = <String, dynamic>{
        'id': customerId,
        'vendor_id': vendorId,
        'name': name,
        'phone': phone,
        'address': address,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (flatNumber != null) customerData['flat_number'] = flatNumber;
      if (floor != null) customerData['floor'] = floor;
      if (buildingName != null) customerData['building_name'] = buildingName;
      if (landmark != null) customerData['landmark'] = landmark;
      if (city != null) customerData['city'] = city;
      if (state != null) customerData['state'] = state;
      if (pincode != null) customerData['pincode'] = pincode;

      final error = await _supabase
          .from('customers')
          .upsert(customerData);

      if (error != null) {
        AppLogger.e('Error upserting customer: $error');
        return {
          'success': false,
          'message': 'Failed to save customer',
          'error': error.toString(),
        };
      }

      AppLogger.i('Customer saved successfully');
      return {
        'success': true,
        'message': 'Customer saved successfully',
      };
    } catch (e) {
      AppLogger.e('Error upserting customer: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }
}
