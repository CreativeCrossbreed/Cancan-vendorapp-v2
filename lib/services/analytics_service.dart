import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

class DayAnalytics {
  final DateTime date;
  final int cansSold;
  final double earnings;
  final int newCustomers;

  DayAnalytics({
    required this.date,
    required this.cansSold,
    required this.earnings,
    required this.newCustomers,
  });
}

/// Analytics Service — aggregates delivery/earnings/customer-growth stats
/// for the vendor's "Analytics" drawer screen (replaces the old home-screen
/// Earnings card, which only showed today's pending-order total).
class AnalyticsService {
  final _supabase = SupabaseConfig.client;

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Returns one entry per day for the last [days] days (oldest first),
  /// including today.
  Future<List<DayAnalytics>> getLastNDaysSummary({int days = 7}) async {
    final vendorId = SupabaseConfig.currentVendorId;
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day).subtract(Duration(days: days - 1));

    if (vendorId == null) {
      return List.generate(
        days,
        (i) => DayAnalytics(date: startDate.add(Duration(days: i)), cansSold: 0, earnings: 0, newCustomers: 0),
      );
    }

    final startDateStr = _dateKey(startDate);

    final cansByDay = <String, int>{};
    final earningsByDay = <String, double>{};
    final newCustomersByDay = <String, int>{};

    try {
      final deliveredOrders = await _supabase
          .from('orders')
          .select('delivery_date, total_amount, order_items(quantity)')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', startDateStr)
          .inFilter('status', ['delivered', 'completed']);

      for (final order in deliveredOrders) {
        final dateStr = order['delivery_date'] as String;
        earningsByDay[dateStr] = (earningsByDay[dateStr] ?? 0) + (order['total_amount'] as num).toDouble();

        final items = order['order_items'] as List? ?? [];
        for (final item in items) {
          cansByDay[dateStr] = (cansByDay[dateStr] ?? 0) + (item['quantity'] as int);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching delivered-orders analytics: $e');
    }

    try {
      final newLinks = await _supabase
          .from('customer_vendors')
          .select('created_at')
          .eq('vendor_id', vendorId)
          .gte('created_at', startDate.toIso8601String());

      for (final link in newLinks) {
        final createdAt = DateTime.parse(link['created_at'] as String);
        final dateStr = _dateKey(createdAt);
        newCustomersByDay[dateStr] = (newCustomersByDay[dateStr] ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('❌ Error fetching new-customer analytics: $e');
    }

    return List.generate(days, (i) {
      final date = startDate.add(Duration(days: i));
      final key = _dateKey(date);
      return DayAnalytics(
        date: date,
        cansSold: cansByDay[key] ?? 0,
        earnings: earningsByDay[key] ?? 0.0,
        newCustomers: newCustomersByDay[key] ?? 0,
      );
    });
  }
}
