import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/order.dart';
import 'inventory_service.dart';

/// Order Service - Handles order management operations
class OrderService {
  final _supabase = SupabaseConfig.client;

  bool _isDeliveredAlias(String status) => status == 'completed' || status == 'delivered';

  /// Updates an order while tolerating schema drift.
  /// If a column is missing in the current DB schema, remove it and retry.
  Future<void> _updateOrderWithFallback({
    required String orderId,
    required Map<String, dynamic> updates,
  }) async {
    final adaptiveUpdates = Map<String, dynamic>.from(updates);

    for (int attempt = 0; attempt < 8; attempt++) {
      try {
        await _supabase.from('orders').update(adaptiveUpdates).eq('id', orderId);
        return;
      } catch (e) {
        final msg = e.toString();
        final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(msg);
        if (match != null) {
          final missingColumn = match.group(1)!;
          if (adaptiveUpdates.containsKey(missingColumn)) {
            adaptiveUpdates.remove(missingColumn);
            debugPrint('⚠️ Retrying order update without missing column: $missingColumn');
            if (adaptiveUpdates.isEmpty) {
              throw Exception('No compatible order fields left to update');
            }
            continue;
          }
        }
        rethrow;
      }
    }

    throw Exception('Failed to update order after schema fallback attempts');
  }

  /// Get orders by date and status
  Future<List<Order>> getOrdersByDate({
    required DateTime date,
    required String status,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        debugPrint('⚠️ User not authenticated - cannot fetch orders');
        return [];
      }
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      debugPrint('📦 Fetching $status orders for $dateStr...');

      final baseQuery = _supabase.from('orders').select('''
            *,
            customers(
              id,
              name,
              phone,
              address,
              flat_number,
              floor,
              building_name,
              created_at,
              updated_at
            ),
            order_items(
              id,
              quantity,
              unit_price,
              subtotal,
              products(id, name)
            )
          ''').eq('vendor_id', vendorId).eq('delivery_date', dateStr);

      final response = _isDeliveredAlias(status)
          ? await baseQuery
              .inFilter('status', ['completed', 'delivered'])
              .order('time_slot', ascending: true)
          : await baseQuery.eq('status', status).order('time_slot', ascending: true);

      debugPrint('✅ Found ${response.length} $status orders for $dateStr');

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching orders for $date: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get orders for today by status
  Future<List<Order>> getTodayOrders({required String status}) async {
    return getOrdersByDate(date: DateTime.now(), status: status);
  }

  /// Get orders by status across all dates
  Future<List<Order>> getOrders({required String status}) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        debugPrint('⚠️ User not authenticated - cannot fetch orders');
        return [];
      }

      debugPrint('📦 Fetching all $status orders...');

      final baseQuery = _supabase.from('orders').select('''
            *,
            customers(
              id,
              name,
              phone,
              address,
              flat_number,
              floor,
              building_name,
              created_at,
              updated_at
            ),
            order_items(
              id,
              quantity,
              unit_price,
              subtotal,
              products(id, name)
            )
          ''').eq('vendor_id', vendorId);

      final response = _isDeliveredAlias(status)
          ? await baseQuery
              .inFilter('status', ['completed', 'delivered'])
              .order('delivery_date', ascending: false)
          : await baseQuery.eq('status', status).order('delivery_date', ascending: false);

      debugPrint('✅ Found ${response.length} $status orders');

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching orders: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return [];
    }
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
        if (_isDeliveredAlias((order['status'] as String?) ?? '')) completed++;
      }

      return {'pending': pending, 'completed': completed};
    } catch (e) {
      debugPrint('❌ Error fetching order counts: $e');
      return {'pending': 0, 'completed': 0};
    }
  }

  /// Get daily summary (total cans and earnings) for today.
  Future<Map<String, dynamic>> getDailySummary() => getDailySummaryForDate(DateTime.now());

  /// Get pending-order summary (total cans and earnings) for an arbitrary date.
  Future<Map<String, dynamic>> getDailySummaryForDate(DateTime date) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        debugPrint('⚠️ User not authenticated - cannot fetch daily summary');
        return {'totalCans': 0, 'totalEarnings': 0.0};
      }

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Get all pending orders for this date
      final orders = await _supabase
          .from('orders')
          .select('''
            id,
            total_amount,
            order_items(quantity)
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
      debugPrint('❌ Error fetching daily summary for $date: $e');
      return {'totalCans': 0, 'totalEarnings': 0.0};
    }
  }

  /// Get unpaid orders across all dates for a vendor.
  /// This fetches all orders that are NOT fully paid (total_amount > amount_paid).
  Future<List<Order>> getUnpaidOrders() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        debugPrint('⚠️ User not authenticated - cannot fetch unpaid orders');
        return [];
      }

      debugPrint('🔍 Fetching all unpaid orders for vendor: $vendorId');

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            customers(
              id,
              name,
              phone,
              address,
              flat_number,
              floor,
              building_name,
              created_at,
              updated_at
            ),
            order_items(
              id,
              quantity,
              unit_price,
              subtotal,
              products(id, name)
            )
          ''')
          .eq('vendor_id', vendorId)
          .order('delivery_date', ascending: false);

      debugPrint('✅ Found ${response.length} total orders');

      // Filter unpaid orders on the client side (where total_amount > amount_paid)
      final unpaidOrders = (response as List).where((json) {
        final totalAmount = (json['total_amount'] as num).toDouble();
        final amountPaid = (json['amount_paid'] ?? 0) as num;
        return totalAmount > amountPaid.toDouble();
      }).toList();

      debugPrint('✅ Found ${unpaidOrders.length} unpaid orders');

      return unpaidOrders.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching unpaid orders: $e');
      return [];
    }
  }

  /// Marks an order delivered (and deducts stock). Does NOT touch payment
  /// fields — for recording a payment, use OrderLifecycleApi.recordCashPayment()
  /// (vendor cash collection, creates a real `payments` audit row) or
  /// PaymentService.recordPayment(). The `isPaid` parameter that used to
  /// live here wrote orders.amount_paid/payment_status directly, bypassing
  /// the payments table entirely and silently diverging from every other
  /// payment-recording path in the app — removed for that reason.
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required bool isDelivered,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (isDelivered) {
        updates['status'] = 'delivered';
        updates['is_delivered'] = true;
        updates['delivered_at'] = DateTime.now().toIso8601String();

        // Deduct stock from inventory when order is delivered
        final inventoryService = InventoryService();
        final stockResult = await inventoryService.deductStockForOrder(orderId: orderId);
        if (!stockResult['success']) {
          debugPrint('⚠️ Warning: ${stockResult['message']}');
        }
      }

      if (updates.isNotEmpty) {
        await _updateOrderWithFallback(orderId: orderId, updates: updates);
        debugPrint('✅ Order $orderId updated successfully');
      }

      return {
        'success': true,
        'message': 'Order updated successfully',
      };
    } catch (e) {
      debugPrint('❌ Error updating order: $e');
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
      }).eq('id', orderId);

      return {
        'success': true,
        'message': 'Order cancelled',
      };
    } catch (e) {
      debugPrint('❌ Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Failed to cancel order',
      };
    }
  }
}
