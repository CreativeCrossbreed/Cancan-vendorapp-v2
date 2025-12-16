import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

/// Customer Service - Handles customer management operations
class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all customers for the current vendor
  Future<List<Customer>> getAllCustomers({
    int? limit,
    int? offset,
    String? searchQuery,
    String? sortBy = 'name',
    bool ascending = true,
  }) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      AppLogger.d('Fetching customers for vendor: $vendorId');

      var query = _supabase
          .from('customers')
          .select('''
            id,
            name,
            phone,
            address,
            flat_number,
            floor,
            building_name,
            created_at
          ''')
          .eq('vendor_id', vendorId);

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,phone.ilike.%$searchQuery%');
      }

      // Apply sorting
      query = query.order(sortBy ?? 'name', ascending: ascending);

      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await query;

      final customers = response.map((json) {
        final customerJson = Map<String, dynamic>.from(json);
        customerJson['vendor_id'] = vendorId; // Add vendor_id for model compatibility
        return Customer.fromJson(customerJson);
      }).toList();

      AppLogger.i('Retrieved ${customers.length} customers');
      return customers;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching customers: $e', e, stackTrace);
      return [];
    }
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      AppLogger.d('Fetching customer: $customerId');

      final response = await _supabase
          .from('customers')
          .select()
          .eq('id', customerId)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response != null) {
        final customerJson = Map<String, dynamic>.from(response);
        customerJson['vendor_id'] = vendorId;
        return Customer.fromJson(customerJson);
      }

      AppLogger.w('Customer not found: $customerId');
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching customer: $e', e, stackTrace);
      return null;
    }
  }

  /// Search customers by phone number or name
  Future<List<Customer>> searchCustomers(String query, {int limit = 10}) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      AppLogger.d('Searching customers with query: $query');

      final response = await _supabase
          .from('customers')
          .select()
          .eq('vendor_id', vendorId)
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .limit(limit);

      final customers = response.map((json) {
        final customerJson = Map<String, dynamic>.from(json);
        customerJson['vendor_id'] = vendorId;
        return Customer.fromJson(customerJson);
      }).toList();

      AppLogger.i('Found ${customers.length} matching customers');
      return customers;
    } catch (e, stackTrace) {
      AppLogger.e('Error searching customers: $e', e, stackTrace);
      return [];
    }
  }

  /// Get customer order history
  Future<List<Order>> getCustomerOrders(String customerId, {
    int? limit = 20,
    String? status,
  }) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      AppLogger.d('Fetching orders for customer: $customerId');

      var query = _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            vendor_id,
            customer_id,
            delivery_date,
            time_slot,
            total_amount,
            status,
            is_delivered,
            delivered_at,
            payment_status,
            payment_marked_at,
            notes,
            cancellation_reason,
            created_at,
            customers!inner(
              id,
              name,
              phone,
              address,
              flat_number,
              floor,
              building_name
            )
          ''')
          .eq('vendor_id', vendorId)
          .eq('customer_id', customerId);

      if (status != null) {
        query = query.eq('status', status);
      }

      query = query.order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      final orders = response.map((json) {
        return Order.fromJson(json);
      }).toList();

      AppLogger.i('Retrieved ${orders.length} orders for customer');
      return orders;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching customer orders: $e', e, stackTrace);
      return [];
    }
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      AppLogger.d('Fetching statistics for customer: $customerId');

      final results = await Future.wait([
        // Total orders
        _supabase
            .from('orders')
            .select('id')
            .eq('vendor_id', vendorId)
            .eq('customer_id', customerId),
        // Completed orders
        _supabase
            .from('orders')
            .select('id, total_amount')
            .eq('vendor_id', vendorId)
            .eq('customer_id', customerId)
            .eq('status', 'completed'),
        // Last order
        _supabase
            .from('orders')
            .select('created_at')
            .eq('vendor_id', vendorId)
            .eq('customer_id', customerId)
            .order('created_at', ascending: false)
            .limit(1),
        // This month orders
        _supabase
            .from('orders')
            .select('id')
            .eq('vendor_id', vendorId)
            .eq('customer_id', customerId)
            .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String()),
      ]);

      final totalOrders = results[0].length as int;
      final completedOrders = results[1] as List;
      final lastOrder = results[2] as List;
      final thisMonthOrders = results[3].length as int;

      double totalSpent = 0.0;
      for (final order in completedOrders) {
        totalSpent += (order['total_amount'] as num).toDouble();
      }

      final averageOrderValue = completedOrders.isNotEmpty
          ? totalSpent / completedOrders.length
          : 0.0;

      DateTime? lastOrderDate;
      if (lastOrder.isNotEmpty) {
        lastOrderDate = DateTime.parse(lastOrder[0]['created_at'] as String);
      }

      final stats = {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders.length,
        'totalSpent': totalSpent,
        'averageOrderValue': averageOrderValue,
        'lastOrderDate': lastOrderDate,
        'thisMonthOrders': thisMonthOrders,
        'customerType': _getCustomerType(totalOrders, totalSpent),
      };

      AppLogger.d('Customer stats retrieved: $stats');
      return stats;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching customer stats: $e', e, stackTrace);
      return {
        'totalOrders': 0,
        'completedOrders': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
        'lastOrderDate': null,
        'thisMonthOrders': 0,
        'customerType': 'New',
      };
    }
  }

  /// Add new customer
  Future<Map<String, dynamic>> addCustomer({
    required String name,
    required String phone,
    required String address,
    String? flatNumber,
    String? floor,
    String? buildingName,
  }) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      // Check if customer already exists for this vendor
      final existingCustomer = await _supabase
          .from('customers')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('phone', phone)
          .maybeSingle();

      if (existingCustomer != null) {
        return {
          'success': false,
          'message': 'Customer with this phone number already exists',
          'customerId': existingCustomer['id'],
        };
      }

      AppLogger.i('Adding new customer: $name ($phone)');

      final customerData = {
        'vendor_id': vendorId,
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'flat_number': flatNumber?.trim(),
        'floor': floor?.trim(),
        'building_name': buildingName?.trim(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('customers')
          .insert(customerData)
          .select('id')
          .single();

      AppLogger.i('Customer added successfully: ${response['id']}');

      return {
        'success': true,
        'message': 'Customer added successfully',
        'customerId': response['id'],
      };
    } catch (e, stackTrace) {
      AppLogger.e('Error adding customer: $e', e, stackTrace);
      return {
        'success': false,
        'message': 'Failed to add customer: ${e.toString()}',
      };
    }
  }

  /// Update customer details
  Future<Map<String, dynamic>> updateCustomer({
    required String customerId,
    String? name,
    String? phone,
    String? address,
    String? flatNumber,
    String? floor,
    String? buildingName,
  }) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      AppLogger.i('Updating customer: $customerId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only include non-null fields
      if (name != null) updateData['name'] = name.trim();
      if (phone != null) updateData['phone'] = phone.trim();
      if (address != null) updateData['address'] = address.trim();
      if (flatNumber != null) updateData['flat_number'] = flatNumber.trim();
      if (floor != null) updateData['floor'] = floor.trim();
      if (buildingName != null) updateData['building_name'] = buildingName.trim();

      await _supabase
          .from('customers')
          .update(updateData)
          .eq('id', customerId)
          .eq('vendor_id', vendorId);

      AppLogger.i('Customer updated successfully');
      return {
        'success': true,
        'message': 'Customer updated successfully',
      };
    } catch (e, stackTrace) {
      AppLogger.e('Error updating customer: $e', e, stackTrace);
      return {
        'success': false,
        'message': 'Failed to update customer: ${e.toString()}',
      };
    }
  }

  /// Get top customers by order value or frequency
  Future<List<Map<String, dynamic>>> getTopCustomers({
    int limit = 10,
    String sortBy = 'totalSpent', // 'totalSpent' or 'orderFrequency'
  }) async {
    try {
      final vendorId = _supabase.auth.currentUser?.id;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      AppLogger.d('Fetching top customers by $sortBy');

      final response = await _supabase
          .from('orders')
          .select('''
            customer_id,
            total_amount,
            customers!inner(
              id,
              name,
              phone,
              address
            )
          ''')
          .eq('vendor_id', vendorId)
          .eq('status', 'completed');

      // Group by customer
      final Map<String, Map<String, dynamic>> customerData = {};

      for (final order in response) {
        final customerId = order['customer_id'] as String;
        final amount = (order['total_amount'] as num).toDouble();

        if (!customerData.containsKey(customerId)) {
          final customer = order['customers'] as Map<String, dynamic>;
          customerData[customerId] = {
            'id': customerId,
            'name': customer['name'],
            'phone': customer['phone'],
            'address': customer['address'],
            'totalOrders': 0,
            'totalSpent': 0.0,
          };
        }

        final customer = customerData[customerId]!;
        customer['totalOrders'] = (customer['totalOrders'] as int) + 1;
        customer['totalSpent'] = (customer['totalSpent'] as double) + amount;
      }

      // Sort by requested criteria
      final sortedCustomers = customerData.values.toList()
        ..sort((a, b) {
          if (sortBy == 'totalSpent') {
            return (b['totalSpent'] as double).compareTo(a['totalSpent'] as double);
          } else {
            return (b['totalOrders'] as int).compareTo(a['totalOrders'] as int);
          }
        });

      final result = sortedCustomers.take(limit).toList();
      AppLogger.i('Retrieved ${result.length} top customers');
      return result;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching top customers: $e', e, stackTrace);
      return [];
    }
  }

  /// Get customer type based on order history
  String _getCustomerType(int totalOrders, double totalSpent) {
    if (totalOrders == 0) return 'New';
    if (totalOrders >= 20 || totalSpent >= 5000) return 'VIP';
    if (totalOrders >= 10 || totalSpent >= 2000) return 'Regular';
    return 'Occasional';
  }
}