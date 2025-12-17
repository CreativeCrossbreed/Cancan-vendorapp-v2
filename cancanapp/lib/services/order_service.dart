import '../config/supabase_config.dart';
import '../models/order.dart';
import '../utils/logger.dart';

/// Order Service - Handles order management operations
class OrderService {
  final _supabase = SupabaseConfig.client;

  
  
  /// Get orders by date and status
  Future<List<Order>> getOrdersByDate({
    required DateTime date,
    required String status,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      AppLogger.d('Fetching $status orders for $dateStr');

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            customers(id, name, phone, address, flat_number, floor, building_name),
            order_items(
              id,
              quantity,
              unit_price,
              subtotal,
              products(id, name)
            )
          ''')
          .eq('vendor_id', vendorId)
          .eq('delivery_date', dateStr)
          .eq('status', status)
          .order('time_slot', ascending: true);

      AppLogger.i('Found ${response.length} $status orders for $dateStr');

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching orders for $date: $e', e, stackTrace);
      return [];
    }
  }

  /// Get orders for today by status
  Future<List<Order>> getTodayOrders({required String status}) async {
    return getOrdersByDate(date: DateTime.now(), status: status);
  }

  /// Get order counts for today
  Future<Map<String, int>> getTodayOrderCounts() async {
    try {

      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) return {'pending': 0, 'completed': 0};

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final allOrders = await _supabase
          .from('orders')
          .select('status')
          .eq('vendor_id', vendorId)
          .eq('delivery_date', dateStr);

      int pending = 0;
      int completed = 0;

      for (final order in allOrders) {
        if (order['status'] == 'pending') pending++;
        if (order['status'] == 'completed') completed++;
      }

      return {'pending': pending, 'completed': completed};
    } catch (e) {
      AppLogger.e('Error fetching order counts: $e');
      return {'pending': 0, 'completed': 0};
    }
  }

  /// Get daily summary (total cans and earnings)
  Future<Map<String, dynamic>> getDailySummary() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get all pending orders for today
      final orders = await _supabase
          .from('orders')
          .select('''
            id,
            total_amount,
            order_items!inner(quantity)
          ''')
          .eq('vendor_id', vendorId)
          .eq('delivery_date', dateStr)
          .eq('status', 'pending');

      int totalCans = 0;
      double totalEarnings = 0.0;

      for (final order in orders) {
        totalEarnings += (order['total_amount'] as num).toDouble();

        final items = order['order_items'] as List;
        for (final item in items) {
          totalCans += (item['quantity'] as int);
        }
      }

      return {'totalCans': totalCans, 'totalEarnings': totalEarnings};
    } catch (e) {
      AppLogger.e('Error fetching daily summary: $e');
      return {'totalCans': 0, 'totalEarnings': 0.0};
    }
  }

  /// Update order status with more options
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required bool isDelivered,
    required bool isPaid,
    String? deliveryNotes,
    String? status, // For more granular status updates
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (status != null) {
        updates['status'] = status;
        if (status == 'completed') {
          updates['is_delivered'] = true;
          updates['delivered_at'] = DateTime.now().toIso8601String();
        } else if (status == 'cancelled') {
          updates['cancelled_at'] = DateTime.now().toIso8601String();
          updates['cancellation_reason'] = deliveryNotes ?? 'Cancelled by vendor';
        }
      } else if (isDelivered) {
        updates['status'] = 'completed';
        updates['is_delivered'] = true;
        updates['delivered_at'] = DateTime.now().toIso8601String();
      }

      if (isPaid) {
        updates['payment_status'] = 'paid';
        updates['payment_marked_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('orders').update(updates).eq('id', orderId);

      AppLogger.i('Order $orderId updated successfully');

      return {
        'success': true,
        'message': 'Order updated successfully',
      };
    } catch (e) {
      AppLogger.e('Error updating order: $e');
      return {
        'success': false,
        'message': 'Failed to update order',
      };
    }
  }

  /// Cancel order
  Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    try {
      await _supabase.from('orders').update({
        'status': 'cancelled',
        'cancellation_reason': reason,
        'cancelled_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return {
        'success': true,
        'message': 'Order cancelled',
      };
    } catch (e) {
      AppLogger.e('Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Failed to cancel order',
      };
    }
  }

  /// Get orders by date range
  Future<List<Order>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      AppLogger.d('Fetching orders from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      var query = _supabase
          .from('orders')
          .select('''
            *,
            customers(id, name, phone, address, flat_number, floor, building_name),
            order_items(
              id,
              quantity,
              unit_price,
              subtotal,
              products(id, name)
            )
          ''')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', startDate.toIso8601String())
          .lte('delivery_date', endDate.toIso8601String())
          .order('delivery_date', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      AppLogger.i('Found ${response.length} orders for date range');

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching orders for date range: $e', e, stackTrace);
      return [];
    }
  }

  /// Get order by ID with full details
  Future<Order?> getOrderById(String orderId) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            customers(id, name, phone, address, flat_number, floor, building_name),
            order_items(
              id,
              quantity,
              unit_price,
              subtotal,
              products(id, name)
            )
          ''')
          .eq('vendor_id', vendorId)
          .eq('id', orderId)
          .single();

      return Order.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching order $orderId: $e', e, stackTrace);
      return null;
    }
  }

  /// Get order statistics for a date range
  Future<Map<String, dynamic>> getOrderStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final orders = await _supabase
          .from('orders')
          .select('status, total_amount, delivery_date')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', startDate.toIso8601String())
          .lte('delivery_date', endDate.toIso8601String());

      int totalOrders = orders.length;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;
      double totalRevenue = 0.0;
      double pendingRevenue = 0.0;

      for (final order in orders) {
        final status = order['status'] as String;
        final amount = (order['total_amount'] as num).toDouble();

        switch (status) {
          case 'pending':
            pendingOrders++;
            pendingRevenue += amount;
            break;
          case 'completed':
            completedOrders++;
            totalRevenue += amount;
            break;
          case 'cancelled':
            cancelledOrders++;
            break;
        }
      }

      final completionRate = totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;
      final averageOrderValue = completedOrders > 0 ? totalRevenue / completedOrders : 0.0;

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalRevenue': totalRevenue,
        'pendingRevenue': pendingRevenue,
        'completionRate': completionRate,
        'averageOrderValue': averageOrderValue,
      };
    } catch (e) {
      AppLogger.e('Error fetching order statistics: $e');
      return {
        'totalOrders': 0,
        'pendingOrders': 0,
        'completedOrders': 0,
        'cancelledOrders': 0,
        'totalRevenue': 0.0,
        'pendingRevenue': 0.0,
        'completionRate': 0.0,
        'averageOrderValue': 0.0,
      };
    }
  }

  /// Search orders by customer name or phone
  Future<List<Order>> searchOrders(String query) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            customers(id, name, phone, address, flat_number, floor, building_name),
            order_items(
              id,
              quantity,
              unit_price,
              subtotal,
              products(id, name)
            )
          ''')
          .eq('vendor_id', vendorId)
          .or('customers.name.ilike.%$query%,customers.phone.ilike.%$query%')
          .order('delivery_date', ascending: false)
          .limit(50);

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e, stackTrace) {
      AppLogger.e('Error searching orders: $e', e, stackTrace);
      return [];
    }
  }

  /// Update delivery notes
  Future<Map<String, dynamic>> updateDeliveryNotes({
    required String orderId,
    required String notes,
  }) async {
    try {
      await _supabase.from('orders').update({
        'delivery_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      return {
        'success': true,
        'message': 'Delivery notes updated',
      };
    } catch (e) {
      AppLogger.e('Error updating delivery notes: $e');
      return {
        'success': false,
        'message': 'Failed to update delivery notes',
      };
    }
  }
}
