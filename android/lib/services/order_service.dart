import '../config/supabase_config.dart';
import '../models/order.dart';
import '../utils/logger.dart';

/// Order Service - Handles order operations with Supabase
class OrderService {
  final _supabase = SupabaseConfig.client;

  /// Get today's orders by status
  Future<List<Order>> getTodayOrders({String? status}) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        AppLogger.w('No vendor ID found');
        return [];
      }

      AppLogger.d('Fetching today orders for vendor: $vendorId, status: $status');

      // Get orders for today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

      // Build query - select first, then filters
      var query = _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            customer_id,
            delivery_date,
            time_slot,
            status,
            payment_status,
            total_amount,
            is_delivered,
            delivered_at,
            payment_marked_at,
            notes,
            created_at,
            customers!inner(
              id,
              name,
              phone,
              address,
              flat_number,
              floor,
              building_name
            ),
            order_items!inner(
              id,
              product_id,
              quantity,
              unit_price,
              subtotal,
              products!inner(
                id,
                name
              )
            )
          ''')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', startOfDay.toIso8601String())
          .lte('delivery_date', endOfDay.toIso8601String());

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      AppLogger.i('Fetched ${response.length} orders');

      // Parse response to Order objects
      return response.map((data) => Order.fromJson(data)).toList();
    } catch (e) {
      AppLogger.e('Error fetching orders: $e');
      return [];
    }
  }

  /// Get orders by date and status (for HistoryScreen)
  Future<List<Order>> getOrdersByDate({
    required DateTime date,
    String? status,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return [];
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

      // Build query - select first, then filters
      var query = _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            customer_id,
            delivery_date,
            time_slot,
            status,
            payment_status,
            total_amount,
            is_delivered,
            delivered_at,
            created_at,
            customers!inner(
              id,
              name,
              phone,
              address,
              flat_number,
              floor,
              building_name
            ),
            order_items!inner(
              id,
              product_id,
              quantity,
              unit_price,
              subtotal,
              products!inner(
                id,
                name
              )
            )
          ''')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', startOfDay.toIso8601String())
          .lte('delivery_date', endOfDay.toIso8601String());

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return response.map((data) => Order.fromJson(data)).toList();
    } catch (e) {
      AppLogger.e('Error fetching orders by date: $e');
      return [];
    }
  }

  /// Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return null;
      }

      AppLogger.d('Fetching order: $orderId');

      final response = await _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            customer_id,
            vendor_id,
            delivery_date,
            time_slot,
            delivery_address,
            status,
            payment_status,
            payment_method,
            subtotal,
            delivery_fee,
            tax_amount,
            total_amount,
            is_delivered,
            delivered_at,
            delivery_otp,
            delivery_notes,
            cancellation_reason,
            cancelled_at,
            payment_marked_at,
            notes,
            created_at,
            updated_at,
            customers!inner(
              id,
              name,
              phone,
              address,
              flat_number,
              floor,
              building_name
            ),
            order_items!inner(
              id,
              order_id,
              product_id,
              product_name,
              quantity,
              unit_price,
              subtotal,
              products!inner(
                id,
                name
              )
            )
          ''')
          .eq('id', orderId)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Order.fromJson(response);
    } catch (e) {
      AppLogger.e('Error fetching order: $e');
      return null;
    }
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? deliveredAt,
    String? deliveryOtp,
    String? deliveryNotes,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Updating order status: $orderId to $status');

      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'delivered' && deliveredAt == null) {
        updateData['delivered_at'] = DateTime.now().toIso8601String();
        updateData['is_delivered'] = true;
      } else if (deliveredAt != null) {
        updateData['delivered_at'] = deliveredAt;
        updateData['is_delivered'] = true;
      }

      if (deliveryOtp != null) {
        updateData['delivery_otp'] = deliveryOtp;
      }

      if (deliveryNotes != null) {
        updateData['delivery_notes'] = deliveryNotes;
      }

      final error = await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .eq('vendor_id', vendorId);

      if (error != null) {
        AppLogger.e('Error updating order status: $error');
        return {
          'success': false,
          'message': 'Failed to update order',
          'error': error.toString(),
        };
      }

      AppLogger.i('Order status updated successfully');
      return {
        'success': true,
        'message': 'Order status updated',
      };
    } catch (e) {
      AppLogger.e('Error updating order status: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Get order history with filters
  Future<List<Order>> getOrderHistory({
    int? limit,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return [];
      }

      AppLogger.d('Fetching order history for vendor: $vendorId');

      // Build query - select first, then filters
      var query = _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            customer_id,
            delivery_date,
            time_slot,
            status,
            payment_status,
            total_amount,
            is_delivered,
            delivered_at,
            created_at,
            customers!inner(
              id,
              name,
              phone
            )
          ''')
          .eq('vendor_id', vendorId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('delivery_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('delivery_date', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      List<dynamic> resultList = response;
      if (limit != null && resultList.length > limit) {
        resultList = resultList.sublist(0, limit);
      }

      AppLogger.i('Fetched ${resultList.length} orders from history');

      return resultList.map((data) => Order.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.e('Error fetching order history: $e');
      return [];
    }
  }

  /// Get daily summary
  Future<Map<String, dynamic>> getDailySummary() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'totalCans': 0,
          'totalEarnings': 0.0,
        };
      }

      AppLogger.d('Fetching daily summary for vendor: $vendorId');

      // Get today's completed orders
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('orders')
          .select('id, total_amount')
          .eq('vendor_id', vendorId)
          .eq('status', 'delivered')
          .gte('delivery_date', startOfDay.toIso8601String())
          .lte('delivery_date', today.toIso8601String());

      final totalEarnings = (response as List)
          .fold<double>(0.0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      final orderIds = response.map((o) => o['id'] as String).toList();

      int totalCans = 0;
      if (orderIds.isNotEmpty) {
        final items = await _supabase
            .from('order_items')
            .select('quantity')
            .inFilter('order_id', orderIds);

        totalCans = (items as List)
            .fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
      }

      return {
        'totalCans': totalCans,
        'totalEarnings': totalEarnings,
      };
    } catch (e) {
      AppLogger.e('Error fetching daily summary: $e');
      return {
        'totalCans': 0,
        'totalEarnings': 0.0,
      };
    }
  }

  /// Subscribe to real-time order updates (simplified - returns empty stream for now)
  Stream<List<Order>> subscribeToOrders() {
    final vendorId = SupabaseConfig.currentVendorId;
    if (vendorId == null) {
      return Stream.value([]);
    }

    AppLogger.d('Subscribing to orders for vendor: $vendorId');

    // TODO: Implement proper realtime subscription with newer Supabase API
    // For now, return an empty stream
    return Stream.value([]);
  }

  /// Mark payment as received
  Future<Map<String, dynamic>> markPaymentReceived({
    required String orderId,
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Marking payment received for order: $orderId');

      final error = await _supabase
          .from('orders')
          .update({
            'payment_status': 'paid',
            'payment_method': paymentMethod,
            'payment_marked_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('vendor_id', vendorId);

      if (error != null) {
        AppLogger.e('Error marking payment: $error');
        return {
          'success': false,
          'message': 'Failed to mark payment',
          'error': error.toString(),
        };
      }

      AppLogger.i('Payment marked successfully');
      return {
        'success': true,
        'message': 'Payment marked as received',
      };
    } catch (e) {
      AppLogger.e('Error marking payment: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }
}
