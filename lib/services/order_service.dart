import '../config/supabase_config.dart';
import '../models/order.dart';
import 'inventory_service.dart';

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
        print('⚠️ User not authenticated - cannot fetch orders');
        return [];
      }
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      print('📦 Fetching $status orders for $dateStr...');

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

      print('✅ Found ${response.length} $status orders for $dateStr');

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e, stackTrace) {
      print('❌ Error fetching orders for $date: $e');
      print('❌ Stack trace: $stackTrace');
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
        print('⚠️ User not authenticated - cannot fetch orders');
        return [];
      }

      print('📦 Fetching all $status orders...');

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
          .eq('status', status)
          .order('delivery_date', ascending: false);

      print('✅ Found ${response.length} $status orders');

      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e, stackTrace) {
      print('❌ Error fetching orders: $e');
      print('❌ Stack trace: $stackTrace');
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
        if (order['status'] == 'completed') completed++;
      }

      return {'pending': pending, 'completed': completed};
    } catch (e) {
      print('❌ Error fetching order counts: $e');
      return {'pending': 0, 'completed': 0};
    }
  }

  /// Get daily summary (total cans and earnings)
  Future<Map<String, dynamic>> getDailySummary() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        print('⚠️ User not authenticated - cannot fetch daily summary');
        return {'totalCans': 0, 'totalEarnings': 0.0};
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
      print('❌ Error fetching daily summary: $e');
      return {'totalCans': 0, 'totalEarnings': 0.0};
    }
  }

  /// Get unpaid orders across all dates for a vendor.
  /// This fetches all orders that are NOT fully paid (total_amount > amount_paid).
  Future<List<Order>> getUnpaidOrders() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        print('⚠️ User not authenticated - cannot fetch unpaid orders');
        return [];
      }

      print('🔍 Fetching all unpaid orders for vendor: $vendorId');

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
          .order('delivery_date', ascending: false);

      print('✅ Found ${response.length} total orders');

      // Filter unpaid orders on the client side (where total_amount > amount_paid)
      final unpaidOrders = (response as List).where((json) {
        final totalAmount = (json['total_amount'] as num).toDouble();
        final amountPaid = (json['amount_paid'] ?? 0) as num;
        return totalAmount > amountPaid.toDouble();
      }).toList();

      print('✅ Found ${unpaidOrders.length} unpaid orders');

      return unpaidOrders.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching unpaid orders: $e');
      return [];
    }
  }

  /// Update order status
  /// Note: For recording payments, use PaymentService.recordPayment() instead
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required bool isDelivered,
    required bool isPaid,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (isDelivered) {
        updates['status'] = 'completed';
        updates['is_delivered'] = true;
        updates['delivered_at'] = DateTime.now().toIso8601String();

        // Deduct stock from inventory when order is delivered
        final inventoryService = InventoryService();
        final stockResult = await inventoryService.deductStockForOrder(orderId: orderId);
        if (!stockResult['success']) {
          print('⚠️ Warning: ${stockResult['message']}');
        }
      }

      if (isPaid) {
        // Get order total amount
        final order = await _supabase
            .from('orders')
            .select('total_amount')
            .eq('id', orderId)
            .single();

        if (order != null) {
          final totalAmount = (order['total_amount'] as num).toDouble();
          // Set amount_paid to total_amount for full payment
          updates['amount_paid'] = totalAmount;
          updates['payment_marked_at'] = DateTime.now().toIso8601String();
          // payment_status will be auto-updated by database trigger
        }
      }

      if (updates.isNotEmpty) {
        await _supabase.from('orders').update(updates).eq('id', orderId);
        print('✅ Order $orderId updated successfully');
      }

      return {
        'success': true,
        'message': 'Order updated successfully',
      };
    } catch (e) {
      print('❌ Error updating order: $e');
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
      print('❌ Error cancelling order: $e');
      return {
        'success': false,
        'message': 'Failed to cancel order',
      };
    }
  }
}
