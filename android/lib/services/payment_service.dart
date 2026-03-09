import '../config/supabase_config.dart';
import '../models/order.dart';

/// Payment Service - Handles payment operations
class PaymentService {
  final _supabase = SupabaseConfig.client;

  /// Record a payment for an order (supports partial payments)
  /// The database trigger will automatically update orders.amount_paid and payment_status
  Future<Map<String, dynamic>> recordPayment({
    required String orderId,
    required double amount,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      // Validate amount
      if (amount <= 0) {
        return {
          'success': false,
          'message': 'Payment amount must be greater than 0',
        };
      }

      // Get order to check if payment exceeds total
      final order = await _supabase
          .from('orders')
          .select('total_amount, amount_paid')
          .eq('id', orderId)
          .single();

      final totalAmount = (order['total_amount'] as num).toDouble();
      final currentAmountPaid = (order['amount_paid'] as num).toDouble();
      final newTotalPaid = currentAmountPaid + amount;

      if (newTotalPaid > totalAmount) {
        return {
          'success': false,
          'message': 'Payment amount (₹$newTotalPaid) exceeds total order amount (₹$totalAmount)',
        };
      }

      // Insert payment record
      await _supabase.from('payments').insert({
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
        'notes': notes,
      });

      print('✅ Payment of ₹$amount recorded for order $orderId');

      return {
        'success': true,
        'message': 'Payment recorded successfully',
        'newAmountPaid': newTotalPaid,
        'remainingAmount': totalAmount - newTotalPaid,
        'paymentStatus': newTotalPaid >= totalAmount ? 'paid' : 'partial',
      };
    } catch (e) {
      print('❌ Error recording payment: $e');
      return {
        'success': false,
        'message': 'Failed to record payment: ${e.toString()}',
      };
    }
  }

  /// Get all payments for an order
  Future<List<Payment>> getOrderPayments({required String orderId}) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching payments: $e');
      return [];
    }
  }

  /// Get payment summary for an order
  Future<Map<String, dynamic>> getOrderPaymentSummary(
      {required String orderId}) async {
    try {
      final order = await _supabase
          .from('orders')
          .select('total_amount, amount_paid, remaining_amount, payment_status')
          .eq('id', orderId)
          .single();

      final payments = await getOrderPayments(orderId: orderId);

      return {
        'success': true,
        'totalAmount': (order['total_amount'] as num).toDouble(),
        'amountPaid': (order['amount_paid'] as num).toDouble(),
        'remainingAmount': (order['remaining_amount'] as num).toDouble(),
        'paymentStatus': order['payment_status'] as String,
        'paymentCount': payments.length,
        'payments': payments,
      };
    } catch (e) {
      print('❌ Error fetching payment summary: $e');
      return {
        'success': false,
        'message': 'Failed to fetch payment summary',
      };
    }
  }

  /// Get all payments across all orders (for vendor)
  Future<List<Payment>> getAllPayments() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) return [];

      // Get all order IDs for this vendor
      final orders = await _supabase
          .from('orders')
          .select('id')
          .eq('vendor_id', vendorId);

      if (orders.isEmpty) return [];

      final orderIds = orders.map((o) => o['id'] as String).toList();

      // Get all payments for these orders
      final response = await _supabase
          .from('payments')
          .select()
          .inFilter('order_id', orderIds)
          .order('created_at', ascending: false);

      return (response as List)
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching all payments: $e');
      return [];
    }
  }

  /// Get today's payment collections
  Future<Map<String, dynamic>> getTodayPaymentsSummary() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {'totalCollected': 0.0, 'paymentCount': 0};
      }

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get all order IDs for this vendor created today
      final orders = await _supabase
          .from('orders')
          .select('id')
          .eq('vendor_id', vendorId)
          .gte('created_at', dateStr);

      if (orders.isEmpty) {
        return {'totalCollected': 0.0, 'paymentCount': 0};
      }

      final orderIds = orders.map((o) => o['id'] as String).toList();

      // Get payments for today from vendor's orders
      final response = await _supabase
          .from('payments')
          .select('amount')
          .inFilter('order_id', orderIds)
          .gte('created_at', dateStr);

      double totalCollected = 0;
      for (final payment in response) {
        totalCollected += (payment['amount'] as num).toDouble();
      }

      return {
        'totalCollected': totalCollected,
        'paymentCount': response.length,
      };
    } catch (e) {
      print('❌ Error fetching today\'s payments: $e');
      return {'totalCollected': 0.0, 'paymentCount': 0};
    }
  }
}
