import 'package:intl/intl.dart';

/// Date Range utility class for analytics filtering
class DateRange {
  final DateTime start;
  final DateTime end;
  final String label;

  DateRange({
    required this.start,
    required this.end,
    required this.label,
  });

  factory DateRange.today() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      label: 'Today',
    );
  }

  factory DateRange.yesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return DateRange(
      start: DateTime(yesterday.year, yesterday.month, yesterday.day),
      end: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
      label: 'Yesterday',
    );
  }

  factory DateRange.thisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return DateRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      label: 'This Week',
    );
  }

  factory DateRange.lastWeek() {
    final now = DateTime.now();
    final startOfLastWeek = now.subtract(Duration(days: now.weekday + 6));
    final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
    return DateRange(
      start: DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day),
      end: DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day, 23, 59, 59),
      label: 'Last Week',
    );
  }

  factory DateRange.thisMonth() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      label: 'This Month',
    );
  }

  factory DateRange.lastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return DateRange(
      start: DateTime(lastMonth.year, lastMonth.month, 1),
      end: DateTime(lastMonth.year, lastMonth.month + 1, 0, 23, 59, 59),
      label: 'Last Month',
    );
  }

  factory DateRange.custom(DateTime start, DateTime end) {
    return DateRange(
      start: start,
      end: end,
      label: '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd, yy').format(end)}',
    );
  }

  int get durationInDays => end.difference(start).inDays + 1;

  bool contains(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    return normalizedDate.isAtSameMomentAs(normalizedStart) ||
        (normalizedDate.isAfter(normalizedStart) && normalizedDate.isBefore(normalizedEnd)) ||
        normalizedDate.isAtSameMomentAs(normalizedEnd);
  }
}

/// Revenue Metrics Model
class RevenueMetrics {
  final double totalRevenue;
  final double averageOrderValue;
  final double revenueGrowth;
  final double totalPendingRevenue;
  final double totalCompletedRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final DateRange dateRange;

  RevenueMetrics({
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.revenueGrowth,
    required this.totalPendingRevenue,
    required this.totalCompletedRevenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.dateRange,
  });

  factory RevenueMetrics.fromJson(Map<String, dynamic> json) {
    return RevenueMetrics(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble() ?? 0.0,
      totalPendingRevenue: (json['total_pending_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCompletedRevenue: (json['total_completed_revenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] as int? ?? 0,
      pendingOrders: json['pending_orders'] as int? ?? 0,
      completedOrders: json['completed_orders'] as int? ?? 0,
      dateRange: json['date_range'] != null
          ? dateRangeFromJson(json['date_range'] as Map<String, dynamic>)
          : DateRange.today(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_revenue': totalRevenue,
      'average_order_value': averageOrderValue,
      'revenue_growth': revenueGrowth,
      'total_pending_revenue': totalPendingRevenue,
      'total_completed_revenue': totalCompletedRevenue,
      'total_orders': totalOrders,
      'pending_orders': pendingOrders,
      'completed_orders': completedOrders,
      'date_range': {
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
        'label': dateRange.label,
      },
    };
  }

  String get formattedTotalRevenue => '₹${totalRevenue.toStringAsFixed(2)}';
  String get formattedAverageOrderValue => '₹${averageOrderValue.toStringAsFixed(2)}';
  String get formattedRevenueGrowth => '${revenueGrowth.isNegative ? '' : '+'}${revenueGrowth.toStringAsFixed(1)}%';
}

/// Sales Data Point for Charts
class SalesDataPoint {
  final DateTime date;
  final double revenue;
  final int orders;
  final int cansDelivered;
  final String label;

  SalesDataPoint({
    required this.date,
    required this.revenue,
    required this.orders,
    required this.cansDelivered,
    String? label,
  }) : label = label ?? DateFormat('MMM dd').format(date);

  factory SalesDataPoint.fromJson(Map<String, dynamic> json) {
    return SalesDataPoint(
      date: DateTime.parse(json['date'] as String),
      revenue: (json['revenue'] as num).toDouble(),
      orders: json['orders'] as int,
      cansDelivered: json['cans_delivered'] as int,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'revenue': revenue,
      'orders': orders,
      'cans_delivered': cansDelivered,
      'label': label,
    };
  }
}

/// Sales Data Model
class SalesData {
  final List<SalesDataPoint> dataPoints;
  final double totalRevenue;
  final int totalOrders;
  final int totalCans;
  final DateRange dateRange;

  SalesData({
    required this.dataPoints,
    required this.totalRevenue,
    required this.totalOrders,
    required this.totalCans,
    required this.dateRange,
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      dataPoints: (json['data_points'] as List?)
          ?.map((item) => SalesDataPoint.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] as int? ?? 0,
      totalCans: json['total_cans'] as int? ?? 0,
      dateRange: json['date_range'] != null
          ? dateRangeFromJson(json['date_range'] as Map<String, dynamic>)
          : DateRange.today(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data_points': dataPoints.map((point) => point.toJson()).toList(),
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'total_cans': totalCans,
      'date_range': {
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
        'label': dateRange.label,
      },
    };
  }

  List<double> get revenueValues => dataPoints.map((point) => point.revenue).toList();
  List<int> get orderValues => dataPoints.map((point) => point.orders).toList();
  List<String> get labels => dataPoints.map((point) => point.label).toList();

  double get averageDailyRevenue => dataPoints.isEmpty ? 0.0 : totalRevenue / dataPoints.length;
  double get averageDailyOrders => dataPoints.isEmpty ? 0.0 : totalOrders / dataPoints.length;
}

/// Customer Segment Data
class CustomerSegment {
  final String name;
  final int count;
  final double revenue;
  final double percentage;

  CustomerSegment({
    required this.name,
    required this.count,
    required this.revenue,
    required this.percentage,
  });

  factory CustomerSegment.fromJson(Map<String, dynamic> json) {
    return CustomerSegment(
      name: json['name'] as String,
      count: json['count'] as int,
      revenue: (json['revenue'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'revenue': revenue,
      'percentage': percentage,
    };
  }
}

/// Customer Insights Model
class CustomerInsights {
  final int totalCustomers;
  final int newCustomers;
  final int returningCustomers;
  final double repeatCustomerRate;
  final double customerRetentionRate;
  final List<CustomerSegment> segments;
  final DateRange dateRange;

  CustomerInsights({
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.repeatCustomerRate,
    required this.customerRetentionRate,
    required this.segments,
    required this.dateRange,
  });

  factory CustomerInsights.fromJson(Map<String, dynamic> json) {
    return CustomerInsights(
      totalCustomers: json['total_customers'] as int? ?? 0,
      newCustomers: json['new_customers'] as int? ?? 0,
      returningCustomers: json['returning_customers'] as int? ?? 0,
      repeatCustomerRate: (json['repeat_customer_rate'] as num?)?.toDouble() ?? 0.0,
      customerRetentionRate: (json['customer_retention_rate'] as num?)?.toDouble() ?? 0.0,
      segments: (json['segments'] as List?)
          ?.map((item) => CustomerSegment.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      dateRange: json['date_range'] != null
          ? dateRangeFromJson(json['date_range'] as Map<String, dynamic>)
          : DateRange.today(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_customers': totalCustomers,
      'new_customers': newCustomers,
      'returning_customers': returningCustomers,
      'repeat_customer_rate': repeatCustomerRate,
      'customer_retention_rate': customerRetentionRate,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'date_range': {
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
        'label': dateRange.label,
      },
    };
  }

  String get formattedRepeatRate => '${repeatCustomerRate.toStringAsFixed(1)}%';
  String get formattedRetentionRate => '${customerRetentionRate.toStringAsFixed(1)}%';
}

/// Performance Trend Data Point
class TrendDataPoint {
  final DateTime period;
  final double value;
  final double? previousValue;
  final double changePercentage;
  final String label;

  TrendDataPoint({
    required this.period,
    required this.value,
    this.previousValue,
    required this.changePercentage,
    String? label,
  }) : label = label ?? DateFormat('MMM dd').format(period);

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      period: DateTime.parse(json['period'] as String),
      value: (json['value'] as num).toDouble(),
      previousValue: (json['previous_value'] as num?)?.toDouble(),
      changePercentage: (json['change_percentage'] as num).toDouble(),
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period.toIso8601String(),
      'value': value,
      'previous_value': previousValue,
      'change_percentage': changePercentage,
      'label': label,
    };
  }

  bool get isPositiveTrend => changePercentage >= 0;
  String get formattedChange => '${changePercentage.isNegative ? '' : '+'}${changePercentage.toStringAsFixed(1)}%';
}

/// Performance Trend Model
class PerformanceTrend {
  final List<TrendDataPoint> revenueTrend;
  final List<TrendDataPoint> orderTrend;
  final List<TrendDataPoint> customerTrend;
  final DateRange dateRange;

  PerformanceTrend({
    required this.revenueTrend,
    required this.orderTrend,
    required this.customerTrend,
    required this.dateRange,
  });

  factory PerformanceTrend.fromJson(Map<String, dynamic> json) {
    return PerformanceTrend(
      revenueTrend: (json['revenue_trend'] as List?)
          ?.map((item) => TrendDataPoint.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      orderTrend: (json['order_trend'] as List?)
          ?.map((item) => TrendDataPoint.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      customerTrend: (json['customer_trend'] as List?)
          ?.map((item) => TrendDataPoint.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      dateRange: json['date_range'] != null
          ? dateRangeFromJson(json['date_range'] as Map<String, dynamic>)
          : DateRange.today(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revenue_trend': revenueTrend.map((point) => point.toJson()).toList(),
      'order_trend': orderTrend.map((point) => point.toJson()).toList(),
      'customer_trend': customerTrend.map((point) => point.toJson()).toList(),
      'date_range': {
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
        'label': dateRange.label,
      },
    };
  }

  TrendDataPoint? get latestRevenueTrend => revenueTrend.isNotEmpty ? revenueTrend.last : null;
  TrendDataPoint? get latestOrderTrend => orderTrend.isNotEmpty ? orderTrend.last : null;
  TrendDataPoint? get latestCustomerTrend => customerTrend.isNotEmpty ? customerTrend.last : null;
}

/// Extended DateRange JSON support
extension DateRangeExtension on DateRange {
  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'label': label,
    };
  }
}

/// Parse DateRange from JSON
DateRange dateRangeFromJson(Map<String, dynamic> json) {
  return DateRange(
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    label: json['label'] as String,
  );
}