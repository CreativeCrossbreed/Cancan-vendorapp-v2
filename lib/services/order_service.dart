import '../config/supabase_config.dart';
import '../models/order.dart';
import 'inventory_service.dart';

/// Order Service - Handles order management operations
class OrderService {
  final _supabase = SupabaseConfig.client;

  // Toggle this to `true` if you want to see dummy data in the app
  // (Home screen pending/completed + History screen).
  // Set to `false` to use real data from Supabase.
  static const bool _useDummyData = true;

  /// Generate dummy orders for a given date & status.
  /// This is used only when `_useDummyData` is true.
  List<Order> _generateDummyOrders({
    required DateTime date,
    required String status,
  }) {
    final baseDate = DateTime(date.year, date.month, date.day);

    // Shared dummy customer & products
    final customer1 = Customer(
      id: 'cust_1',
      name: 'Sivanesan V',
      phone: '+919876543210',
      address: 'Lake View Society, Sector 21, Mumbai',
      flatNumber: 'A-201',
      floor: '2',
      buildingName: 'Lake View',
    );

    final customer2 = Customer(
      id: 'cust_2',
      name: 'Akhilan V',
      phone: '+919812345678',
      address: 'Green Gardens, Near City Mall, Pune',
      flatNumber: 'B-502',
      floor: '5',
      buildingName: 'Green Gardens',
    );

    final customer3 = Customer(
      id: 'cust_3',
      name: 'Karthikeyan',
      phone: '+919876501234',
      address: 'Sunrise Apartments, MG Road, Chennai',
      flatNumber: 'C-305',
      floor: '3',
      buildingName: 'Sunrise Apartments',
    );

    final customer4 = Customer(
      id: 'cust_4',
      name: 'Selvakumari',
      phone: '+919812309876',
      address: 'Royal Heights, Anna Nagar, Chennai',
      flatNumber: 'D-102',
      floor: '1',
      buildingName: 'Royal Heights',
    );

    final product20L = Product(id: 'prod_20l', name: '20L Water Can');
    final product10L = Product(id: 'prod_10l', name: '10L Water Can');

    List<Order> pendingOrders = [
      Order(
        id: 'order_pending_1',
        orderNumber: '#1001',
        vendorId: 'dummy_vendor_1',
        customerId: customer1.id,
        deliveryDate: baseDate,
        timeSlot: '8:00 AM - 10:00 AM',
        totalAmount: 140,
        status: 'pending',
        isDelivered: false,
        deliveredAt: null,
        paymentStatus: 'unpaid',
        paymentMarkedAt: null,
        notes: 'Leave at the door',
        cancellationReason: null,
        createdAt: baseDate.subtract(const Duration(hours: 2)),
        customer: customer1,
        items: [
          OrderItem(
            id: 'item_p1_1',
            orderId: 'order_pending_1',
            productId: product20L.id,
            quantity: 2,
            unitPrice: 70,
            subtotal: 140,
            product: product20L,
          ),
        ],
      ),
      Order(
        id: 'order_pending_2',
        orderNumber: '#1002',
        vendorId: 'dummy_vendor_1',
        customerId: customer2.id,
        deliveryDate: baseDate,
        timeSlot: '10:00 AM - 12:00 PM',
        totalAmount: 210,
        status: 'pending',
        isDelivered: false,
        deliveredAt: null,
        paymentStatus: 'unpaid',
        paymentMarkedAt: null,
        notes: 'Call when outside the gate',
        cancellationReason: null,
        createdAt: baseDate.subtract(const Duration(hours: 1)),
        customer: customer2,
        items: [
          OrderItem(
            id: 'item_p2_1',
            orderId: 'order_pending_2',
            productId: product20L.id,
            quantity: 3,
            unitPrice: 70,
            subtotal: 210,
            product: product20L,
          ),
        ],
      ),
    ];

    List<Order> completedOrders = [
      Order(
        id: 'order_completed_1',
        orderNumber: '#0950',
        vendorId: 'dummy_vendor_1',
        customerId: customer1.id,
        deliveryDate: baseDate,
        timeSlot: '6:00 AM - 8:00 AM',
        totalAmount: 200,
        status: 'completed',
        isDelivered: true,
        deliveredAt: baseDate.add(const Duration(hours: 7, minutes: 30)),
        paymentStatus: 'paid',
        paymentMarkedAt: baseDate.add(const Duration(hours: 7, minutes: 35)),
        notes: 'Cash collected',
        cancellationReason: null,
        createdAt: baseDate.subtract(const Duration(days: 1)),
        customer: customer1,
        items: [
          OrderItem(
            id: 'item_c1_1',
            orderId: 'order_completed_1',
            productId: product20L.id,
            quantity: 2,
            unitPrice: 80,
            subtotal: 160,
            product: product20L,
          ),
          OrderItem(
            id: 'item_c1_2',
            orderId: 'order_completed_1',
            productId: product10L.id,
            quantity: 2,
            unitPrice: 20,
            subtotal: 40,
            product: product10L,
          ),
        ],
      ),
      Order(
        id: 'order_completed_2',
        orderNumber: '#0951',
        vendorId: 'dummy_vendor_1',
        customerId: customer3.id,
        deliveryDate: baseDate,
        timeSlot: '8:00 AM - 10:00 AM',
        totalAmount: 140,
        status: 'completed',
        isDelivered: true,
        deliveredAt: baseDate.add(const Duration(hours: 9, minutes: 15)),
        paymentStatus: 'paid',
        paymentMarkedAt: baseDate.add(const Duration(hours: 9, minutes: 20)),
        notes: 'UPI payment',
        cancellationReason: null,
        createdAt: baseDate.subtract(const Duration(days: 1)),
        customer: customer3,
        items: [
          OrderItem(
            id: 'item_c2_1',
            orderId: 'order_completed_2',
            productId: product20L.id,
            quantity: 2,
            unitPrice: 70,
            subtotal: 140,
            product: product20L,
          ),
        ],
      ),
    ];

    List<Order> cancelledOrders = [
      Order(
        id: 'order_cancelled_1',
        orderNumber: '#0888',
        vendorId: 'dummy_vendor_1',
        customerId: customer4.id,
        deliveryDate: baseDate,
        timeSlot: '4:00 PM - 6:00 PM',
        totalAmount: 140,
        status: 'cancelled',
        isDelivered: false,
        deliveredAt: null,
        paymentStatus: 'unpaid',
        paymentMarkedAt: null,
        notes: 'Customer not at home',
        cancellationReason: 'Customer cancelled via phone',
        createdAt: baseDate.subtract(const Duration(days: 2)),
        customer: customer4,
        items: [
          OrderItem(
            id: 'item_x1_1',
            orderId: 'order_cancelled_1',
            productId: product20L.id,
            quantity: 2,
            unitPrice: 70,
            subtotal: 140,
            product: product20L,
          ),
        ],
      ),
    ];

    switch (status) {
      case 'pending':
        return pendingOrders;
      case 'completed':
        return completedOrders;
      case 'cancelled':
        return cancelledOrders;
      default:
        return [];
    }
  }

  /// Get orders by date and status
  Future<List<Order>> getOrdersByDate({
    required DateTime date,
    required String status,
  }) async {
    if (_useDummyData) {
      return _generateDummyOrders(date: date, status: status);
    }

    try {
      final vendorId = SupabaseConfig.currentVendorId ??
          '5d4b8601-2bef-4ce3-8631-b62730d403ea';
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

  /// Get order counts for today
  Future<Map<String, int>> getTodayOrderCounts() async {
    try {
      if (_useDummyData) {
        final pending =
            await getOrdersByDate(date: DateTime.now(), status: 'pending');
        final completed =
            await getOrdersByDate(date: DateTime.now(), status: 'completed');
        return {'pending': pending.length, 'completed': completed.length};
      }

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
      if (_useDummyData) {
        // Use only pending orders for "to be delivered" summary
        final pending =
            await getOrdersByDate(date: DateTime.now(), status: 'pending');

        int totalCans = 0;
        double totalEarnings = 0.0;

        for (final order in pending) {
          totalEarnings += order.totalAmount;
          for (final item in order.items) {
            totalCans += item.quantity;
          }
        }

        return {'totalCans': totalCans, 'totalEarnings': totalEarnings};
      }

      // In test mode, use hardcoded vendor ID
      final vendorId = SupabaseConfig.currentVendorId ??
          '5d4b8601-2bef-4ce3-8631-b62730d403ea';

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
      print('❌ Error fetching daily summary: $e');
      return {'totalCans': 0, 'totalEarnings': 0.0};
    }
  }

  /// Update order status
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
        updates['payment_status'] = 'paid';
        updates['payment_marked_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('orders').update(updates).eq('id', orderId);

      print('✅ Order $orderId updated successfully');

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
