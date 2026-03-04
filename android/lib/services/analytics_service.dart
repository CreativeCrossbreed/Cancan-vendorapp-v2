import '../config/supabase_config.dart';
import '../models/analytics_data.dart';
import '../utils/logger.dart';

/// Analytics Service - Handles data aggregation and analytics calculations
class AnalyticsService {
  final _supabase = SupabaseConfig.client;

  /// Get revenue metrics for a date range
  Future<RevenueMetrics> getRevenueMetrics({
    DateRange? dateRange,
    String? vendorId,
  }) async {
    try {
      final effectiveVendorId = vendorId ?? SupabaseConfig.currentVendorId;
      if (effectiveVendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final range = dateRange ?? DateRange.thisMonth();

      AppLogger.d('Fetching revenue metrics for vendor: $effectiveVendorId, range: ${range.label}');

      // Get all orders in the date range
      final orders = await _supabase
          .from('orders')
          .select('total_amount, status, payment_status')
          .eq('vendor_id', effectiveVendorId)
          .gte('delivery_date', range.start.toIso8601String())
          .lte('delivery_date', range.end.toIso8601String());

      // Calculate metrics
      double totalRevenue = 0.0;
      double totalPendingRevenue = 0.0;
      double totalCompletedRevenue = 0.0;
      int totalOrders = 0;
      int pendingOrders = 0;
      int completedOrders = 0;

      for (final order in orders) {
        final amount = (order['total_amount'] as num).toDouble();
        final status = order['status'] as String;
        final paymentStatus = order['payment_status'] as String;

        totalOrders++;
        totalRevenue += amount;

        if (status == 'pending') {
          pendingOrders++;
          if (paymentStatus != 'paid') {
            totalPendingRevenue += amount;
          }
        } else if (status == 'completed') {
          completedOrders++;
          totalCompletedRevenue += amount;
        }
      }

      // Calculate previous period for growth comparison
      final previousRange = _getPreviousPeriodRange(range);
      final previousRevenue = await _getRevenueForRange(effectiveVendorId, previousRange);
      final revenueGrowth = previousRevenue > 0
          ? ((totalRevenue - previousRevenue) / previousRevenue) * 100
          : 0.0;

      final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      final metrics = RevenueMetrics(
        totalRevenue: totalRevenue,
        averageOrderValue: averageOrderValue,
        revenueGrowth: revenueGrowth,
        totalPendingRevenue: totalPendingRevenue,
        totalCompletedRevenue: totalCompletedRevenue,
        totalOrders: totalOrders,
        pendingOrders: pendingOrders,
        completedOrders: completedOrders,
        dateRange: range,
      );

      AppLogger.i('Revenue metrics calculated: ${metrics.formattedTotalRevenue} revenue, ${metrics.totalOrders} orders');
      return metrics;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching revenue metrics: $e', e, stackTrace);
      return RevenueMetrics(
        totalRevenue: 0.0,
        averageOrderValue: 0.0,
        revenueGrowth: 0.0,
        totalPendingRevenue: 0.0,
        totalCompletedRevenue: 0.0,
        totalOrders: 0,
        pendingOrders: 0,
        completedOrders: 0,
        dateRange: dateRange ?? DateRange.thisMonth(),
      );
    }
  }

  /// Get sales data for charts
  Future<SalesData> getSalesData({
    DateRange? dateRange,
    String? vendorId,
    bool groupByDay = true,
  }) async {
    try {
      final effectiveVendorId = vendorId ?? SupabaseConfig.currentVendorId;
      if (effectiveVendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final range = dateRange ?? DateRange.thisMonth();

      AppLogger.d('Fetching sales data for vendor: $effectiveVendorId, range: ${range.label}');

      // Get orders with item details
      final orders = await _supabase
          .from('orders')
          .select('''
            total_amount,
            delivery_date,
            status,
            order_items!inner(quantity)
          ''')
          .eq('vendor_id', effectiveVendorId)
          .gte('delivery_date', range.start.toIso8601String())
          .lte('delivery_date', range.end.toIso8601String())
          .eq('status', 'completed'); // Only include completed orders

      // Group data points
      final Map<DateTime, SalesDataPoint> dataPointMap = {};
      double totalRevenue = 0.0;
      int totalOrders = 0;
      int totalCans = 0;

      for (final order in orders) {
        final deliveryDate = DateTime.parse(order['delivery_date'] as String);
        final amount = (order['total_amount'] as num).toDouble();
        final items = order['order_items'] as List;
        int cansForOrder = 0;

        for (final item in items) {
          cansForOrder += (item['quantity'] as int);
        }

        // Normalize date for grouping
        final normalizedDate = DateTime(deliveryDate.year, deliveryDate.month, deliveryDate.day);

        if (dataPointMap.containsKey(normalizedDate)) {
          final existingPoint = dataPointMap[normalizedDate]!;
          dataPointMap[normalizedDate] = SalesDataPoint(
            date: normalizedDate,
            revenue: existingPoint.revenue + amount,
            orders: existingPoint.orders + 1,
            cansDelivered: existingPoint.cansDelivered + cansForOrder,
          );
        } else {
          dataPointMap[normalizedDate] = SalesDataPoint(
            date: normalizedDate,
            revenue: amount,
            orders: 1,
            cansDelivered: cansForOrder,
          );
        }

        totalRevenue += amount;
        totalOrders += 1;
        totalCans += cansForOrder;
      }

      // Sort data points by date
      final dataPoints = dataPointMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      return SalesData(
        dataPoints: dataPoints,
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        totalCans: totalCans,
        dateRange: range,
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching sales data: $e', e, stackTrace);
      return SalesData(
        dataPoints: [],
        totalRevenue: 0.0,
        totalOrders: 0,
        totalCans: 0,
        dateRange: dateRange ?? DateRange.thisMonth(),
      );
    }
  }

  /// Get customer insights
  Future<CustomerInsights> getCustomerInsights({
    DateRange? dateRange,
    String? vendorId,
  }) async {
    try {
      final effectiveVendorId = vendorId ?? SupabaseConfig.currentVendorId;
      if (effectiveVendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final range = dateRange ?? DateRange.thisMonth();

      AppLogger.d('Fetching customer insights for vendor: $effectiveVendorId, range: ${range.label}');

      // Get orders with customer details
      final orders = await _supabase
          .from('orders')
          .select('''
            customer_id,
            total_amount,
            delivery_date,
            customers!inner(name, phone, created_at)
          ''')
          .eq('vendor_id', effectiveVendorId)
          .gte('delivery_date', range.start.toIso8601String())
          .lte('delivery_date', range.end.toIso8601String());

      // Analyze customer data
      final Set<String> uniqueCustomers = {};
      final Set<String> newCustomers = {};
      final Set<String> returningCustomers = {};
      final Map<String, double> customerRevenue = {};

      for (final order in orders) {
        final customerId = order['customer_id'] as String;
        final amount = (order['total_amount'] as num).toDouble();
        final customerData = order['customers'] as Map<String, dynamic>;
        final customerCreatedAt = DateTime.parse(customerData['created_at'] as String);

        uniqueCustomers.add(customerId);
        customerRevenue[customerId] = (customerRevenue[customerId] ?? 0) + amount;

        // Check if customer is new in this period
        if (customerCreatedAt.isAfter(range.start.subtract(const Duration(days: 1)))) {
          newCustomers.add(customerId);
        } else {
          returningCustomers.add(customerId);
        }
      }

      final totalCustomers = uniqueCustomers.length;
      final newCustomerCount = newCustomers.length;
      final returningCustomerCount = returningCustomers.length;

      final repeatCustomerRate = totalCustomers > 0
          ? (returningCustomerCount / totalCustomers) * 100
          : 0.0;

      // Calculate customer retention rate (simplified)
      final previousRange = _getPreviousPeriodRange(range);
      final previousCustomers = await _getUniqueCustomersInRange(effectiveVendorId, previousRange);
      final retainedCustomers = uniqueCustomers.where(previousCustomers.contains).length;
      final retentionRate = previousCustomers.isNotEmpty
          ? (retainedCustomers / previousCustomers.length) * 100
          : 0.0;

      // Create customer segments
      final segments = _createCustomerSegments(customerRevenue, totalCustomers);

      return CustomerInsights(
        totalCustomers: totalCustomers,
        newCustomers: newCustomerCount,
        returningCustomers: returningCustomerCount,
        repeatCustomerRate: repeatCustomerRate,
        customerRetentionRate: retentionRate,
        segments: segments,
        dateRange: range,
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching customer insights: $e', e, stackTrace);
      return CustomerInsights(
        totalCustomers: 0,
        newCustomers: 0,
        returningCustomers: 0,
        repeatCustomerRate: 0.0,
        customerRetentionRate: 0.0,
        segments: [],
        dateRange: dateRange ?? DateRange.thisMonth(),
      );
    }
  }

  /// Get performance trends
  Future<PerformanceTrend> getPerformanceTrends({
    DateRange? dateRange,
    String? vendorId,
    int periodCount = 7, // Number of periods to analyze
  }) async {
    try {
      final effectiveVendorId = vendorId ?? SupabaseConfig.currentVendorId;
      if (effectiveVendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final range = dateRange ?? DateRange.thisMonth();

      AppLogger.d('Fetching performance trends for vendor: $effectiveVendorId, periods: $periodCount');

      // Generate trend data points
      final List<TrendDataPoint> revenueTrend = [];
      final List<TrendDataPoint> orderTrend = [];
      final List<TrendDataPoint> customerTrend = [];

      for (int i = periodCount - 1; i >= 0; i--) {
        final periodStart = range.start.subtract(Duration(days: i * 7));
        final periodEnd = periodStart.add(const Duration(days: 6, hours: 23, minutes: 59));
        final periodRange = DateRange.custom(periodStart, periodEnd);
        final previousPeriodRange = DateRange.custom(
          periodStart.subtract(const Duration(days: 7)),
          periodEnd.subtract(const Duration(days: 7)),
        );

        // Revenue trend
        final periodRevenue = await _getRevenueForRange(effectiveVendorId, periodRange);
        final previousRevenue = await _getRevenueForRange(effectiveVendorId, previousPeriodRange);
        final revenueChange = previousRevenue > 0
            ? ((periodRevenue - previousRevenue) / previousRevenue) * 100
            : 0.0;

        // Order trend
        final periodOrders = await _getOrderCountForRange(effectiveVendorId, periodRange);
        final previousOrders = await _getOrderCountForRange(effectiveVendorId, previousPeriodRange);
        final orderChange = previousOrders > 0
            ? ((periodOrders - previousOrders) / previousOrders) * 100
            : 0.0;

        // Customer trend
        final periodCustomers = await _getUniqueCustomersInRange(effectiveVendorId, periodRange);
        final previousCustomers = await _getUniqueCustomersInRange(effectiveVendorId, previousPeriodRange);
        final customerChange = previousCustomers.isNotEmpty
            ? ((periodCustomers.length - previousCustomers.length) / previousCustomers.length) * 100
            : 0.0;

        revenueTrend.add(TrendDataPoint(
          period: periodStart,
          value: periodRevenue,
          previousValue: previousRevenue,
          changePercentage: revenueChange,
        ));

        orderTrend.add(TrendDataPoint(
          period: periodStart,
          value: periodOrders.toDouble(),
          previousValue: previousOrders.toDouble(),
          changePercentage: orderChange,
        ));

        customerTrend.add(TrendDataPoint(
          period: periodStart,
          value: periodCustomers.length.toDouble(),
          previousValue: previousCustomers.length.toDouble(),
          changePercentage: customerChange,
        ));
      }

      return PerformanceTrend(
        revenueTrend: revenueTrend,
        orderTrend: orderTrend,
        customerTrend: customerTrend,
        dateRange: range,
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching performance trends: $e', e, stackTrace);
      return PerformanceTrend(
        revenueTrend: [],
        orderTrend: [],
        customerTrend: [],
        dateRange: dateRange ?? DateRange.thisMonth(),
      );
    }
  }

  /// Export analytics data to JSON
  Future<Map<String, dynamic>> exportAnalyticsData({
    DateRange? dateRange,
    String? vendorId,
  }) async {
    try {
      final range = dateRange ?? DateRange.thisMonth();

      final metrics = await getRevenueMetrics(dateRange: range, vendorId: vendorId);
      final salesData = await getSalesData(dateRange: range, vendorId: vendorId);
      final customerInsights = await getCustomerInsights(dateRange: range, vendorId: vendorId);
      final performanceTrend = await getPerformanceTrends(dateRange: range, vendorId: vendorId);

      return {
        'export_date': DateTime.now().toIso8601String(),
        'date_range': range.toJson(),
        'revenue_metrics': metrics.toJson(),
        'sales_data': salesData.toJson(),
        'customer_insights': customerInsights.toJson(),
        'performance_trend': performanceTrend.toJson(),
      };
    } catch (e, stackTrace) {
      AppLogger.e('Error exporting analytics data: $e', e, stackTrace);
      return {
        'export_date': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // Private helper methods

  Future<double> _getRevenueForRange(String vendorId, DateRange range) async {
    try {
      final orders = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', range.start.toIso8601String())
          .lte('delivery_date', range.end.toIso8601String())
          .eq('status', 'completed');

      double totalRevenue = 0.0;
      for (final order in orders) {
        totalRevenue += (order['total_amount'] as num).toDouble();
      }
      return totalRevenue;
    } catch (e) {
      AppLogger.e('Error getting revenue for range: $e');
      return 0.0;
    }
  }

  Future<int> _getOrderCountForRange(String vendorId, DateRange range) async {
    try {
      final count = await _supabase
          .from('orders')
          .select('id')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', range.start.toIso8601String())
          .lte('delivery_date', range.end.toIso8601String())
          .eq('status', 'completed');

      return count.length;
    } catch (e) {
      AppLogger.e('Error getting order count for range: $e');
      return 0;
    }
  }

  Future<Set<String>> _getUniqueCustomersInRange(String vendorId, DateRange range) async {
    try {
      final orders = await _supabase
          .from('orders')
          .select('customer_id')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', range.start.toIso8601String())
          .lte('delivery_date', range.end.toIso8601String())
          .eq('status', 'completed');

      final Set<String> uniqueCustomers = {};
      for (final order in orders) {
        uniqueCustomers.add(order['customer_id'] as String);
      }
      return uniqueCustomers;
    } catch (e) {
      AppLogger.e('Error getting unique customers for range: $e');
      return <String>{};
    }
  }

  DateRange _getPreviousPeriodRange(DateRange currentRange) {
    final duration = currentRange.durationInDays;
    final previousStart = currentRange.start.subtract(Duration(days: duration));
    final previousEnd = currentRange.end.subtract(Duration(days: duration));
    return DateRange.custom(previousStart, previousEnd);
  }

  List<CustomerSegment> _createCustomerSegments(Map<String, double> customerRevenue, int totalCustomers) {
    if (customerRevenue.isEmpty || totalCustomers == 0) return [];

    final sortedCustomers = customerRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top20Percent = (totalCustomers * 0.2).ceil();
    final next30Percent = (totalCustomers * 0.3).ceil();

    double top20Revenue = 0.0;
    double next30Revenue = 0.0;
    double bottom50Revenue = 0.0;

    for (int i = 0; i < sortedCustomers.length; i++) {
      final revenue = sortedCustomers[i].value;
      if (i < top20Percent) {
        top20Revenue += revenue;
      } else if (i < top20Percent + next30Percent) {
        next30Revenue += revenue;
      } else {
        bottom50Revenue += revenue;
      }
    }

    final totalRevenue = customerRevenue.values.fold(0.0, (sum, value) => sum + value);

    return [
      CustomerSegment(
        name: 'Top 20% (VIP)',
        count: top20Percent,
        revenue: top20Revenue,
        percentage: totalRevenue > 0 ? (top20Revenue / totalRevenue) * 100 : 0.0,
      ),
      CustomerSegment(
        name: 'Next 30%',
        count: next30Percent,
        revenue: next30Revenue,
        percentage: totalRevenue > 0 ? (next30Revenue / totalRevenue) * 100 : 0.0,
      ),
      CustomerSegment(
        name: 'Bottom 50%',
        count: totalCustomers - top20Percent - next30Percent,
        revenue: bottom50Revenue,
        percentage: totalRevenue > 0 ? (bottom50Revenue / totalRevenue) * 100 : 0.0,
      ),
    ];
  }

  /// Get revenue data for charts (dashboard specific)
  Future<List<Map<String, dynamic>>> getRevenueData({
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
          .select('delivery_date, total_amount')
          .eq('vendor_id', vendorId)
          .gte('delivery_date', startDate.toIso8601String())
          .lte('delivery_date', endDate.toIso8601String())
          .eq('status', 'completed')
          .order('delivery_date');

      final List<Map<String, dynamic>> revenueData = [];
      for (final order in orders) {
        revenueData.add({
          'date': order['delivery_date'],
          'revenue': (order['total_amount'] as num).toDouble(),
        });
      }

      return revenueData;
    } catch (e) {
      AppLogger.e('Error getting revenue data: $e');
      return [];
    }
  }

  /// Get top products for dashboard
  Future<List<Map<String, dynamic>>> getTopProducts({
    required int limit,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final products = await _supabase
          .from('order_items')
          .select('''
            quantity,
            products!inner(name)
          ''')
          .eq('orders.vendor_id', vendorId)
          .gte('orders.delivery_date', startDate.toIso8601String())
          .lte('orders.delivery_date', endDate.toIso8601String())
          .eq('orders.status', 'completed');

      final Map<String, int> productCounts = {};
      for (final item in products) {
        final productName = item['products']['name'] as String;
        final quantity = item['quantity'] as int;
        productCounts[productName] = (productCounts[productName] ?? 0) + quantity;
      }

      final sortedProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedProducts
          .take(limit)
          .map((entry) => {
                'name': entry.key,
                'quantity': entry.value,
              })
          .toList();
    } catch (e) {
      AppLogger.e('Error getting top products: $e');
      return [];
    }
  }

  /// Get customer insights for dashboard
  Future<List<Map<String, dynamic>>> getTopCustomers({
    required int limit,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final customers = await _supabase
          .from('orders')
          .select('''
            customers!inner(name, phone)
          ''')
          .eq('vendor_id', vendorId)
          .eq('status', 'completed');

      final Map<String, Map<String, dynamic>> customerData = {};
      for (final order in customers) {
        final customer = order['customers'] as Map<String, dynamic>;
        final customerId = customer['phone'] as String;

        if (!customerData.containsKey(customerId)) {
          customerData[customerId] = {
            'name': customer['name'],
            'phone': customer['phone'],
            'orderCount': 0,
          };
        }
        final data = customerData[customerId]!;
        data['orderCount'] = (data['orderCount'] as int) + 1;
      }

      final sortedCustomers = customerData.values.toList()
        ..sort((a, b) => (b['orderCount'] as int).compareTo(a['orderCount'] as int));

      return sortedCustomers.take(limit).toList();
    } catch (e) {
      AppLogger.e('Error getting customer insights: $e');
      return [];
    }
  }

  /// Get quick stats for dashboard
  Future<Map<String, dynamic>> getQuickStats() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

      // Get total customers
      final customersCount = await _supabase
          .from('orders')
          .select('customer_id')
          .eq('vendor_id', vendorId)
          .not('customer_id', 'is', null);

      final uniqueCustomers = customersCount.map((order) => order['customer_id'] as String).toSet().length;

      // Get this month's completed orders
      final thisMonthOrders = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('vendor_id', vendorId)
          .eq('status', 'completed')
          .gte('created_at', thisMonthStart.toIso8601String());

      // Get last month's completed orders for comparison
      final lastMonthOrders = await _supabase
          .from('orders')
          .select('total_amount')
          .eq('vendor_id', vendorId)
          .eq('status', 'completed')
          .gte('created_at', lastMonthStart.toIso8601String())
          .lte('created_at', lastMonthEnd.toIso8601String());

      // Calculate this month's revenue and stats
      double thisMonthRevenue = 0.0;
      for (final order in thisMonthOrders) {
        thisMonthRevenue += (order['total_amount'] as num).toDouble();
      }

      // Calculate last month's revenue for growth
      double lastMonthRevenue = 0.0;
      for (final order in lastMonthOrders) {
        lastMonthRevenue += (order['total_amount'] as num).toDouble();
      }

      final avgOrderValue = thisMonthOrders.isNotEmpty ? thisMonthRevenue / thisMonthOrders.length : 0.0;
      final deliveryRate = customersCount.isNotEmpty ? (thisMonthOrders.length / customersCount.length) * 100 : 0.0;

      // Calculate growth percentages
      final revenueGrowth = lastMonthRevenue > 0
          ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100
          : 0.0;

      const orderValueGrowth = 0.0; // Would need historical data for accurate calculation
      const customerGrowth = 0.0; // Would need historical customer data
      const deliveryGrowth = 0.0; // Would need historical delivery data

      return {
        'totalCustomers': uniqueCustomers,
        'avgOrderValue': avgOrderValue,
        'totalRevenue': thisMonthRevenue,
        'deliveryRate': deliveryRate,
        'customerGrowth': customerGrowth,
        'orderValueGrowth': orderValueGrowth,
        'revenueGrowth': revenueGrowth,
        'deliveryGrowth': deliveryGrowth,
      };
    } catch (e) {
      AppLogger.e('Error getting quick stats: $e');
      return {
        'totalCustomers': 0,
        'avgOrderValue': 0.0,
        'totalRevenue': 0.0,
        'deliveryRate': 0.0,
        'customerGrowth': 0.0,
        'orderValueGrowth': 0.0,
        'revenueGrowth': 0.0,
        'deliveryGrowth': 0.0,
      };
    }
  }
}