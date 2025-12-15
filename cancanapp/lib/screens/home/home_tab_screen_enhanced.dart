import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import 'widgets/update_status_modal.dart';
import 'widgets/app_drawer.dart';
import 'widgets/quick_stats_card.dart';
import 'widgets/revenue_trend_chart.dart';
import 'widgets/top_products_chart.dart';
import 'widgets/customer_insights_card.dart';
import 'widgets/date_range_selector.dart';
import 'history/history_screen.dart';
import 'payments/payments_screen.dart';
import 'inventory/inventory_screen.dart';

/// Enhanced Home Screen - Main Dashboard with Analytics
class HomeScreenEnhanced extends StatefulWidget {
  const HomeScreenEnhanced({super.key});

  @override
  State<HomeScreenEnhanced> createState() => _HomeScreenEnhancedState();
}

class _HomeScreenEnhancedState extends State<HomeScreenEnhanced> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build screens directly in the body based on index
    Widget currentScreen;
    switch (_selectedIndex) {
      case 0:
        currentScreen = const HomeTabScreenEnhanced();
        break;
      case 1:
        currentScreen = const HistoryScreen();
        break;
      case 2:
        currentScreen = const PaymentsScreen();
        break;
      case 3:
        currentScreen = const InventoryScreen();
        break;
      default:
        currentScreen = const HomeTabScreenEnhanced();
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            activeIcon: Icon(Icons.payment),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            activeIcon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
        ],
      ),
    );
  }
}

/// Enhanced Home Tab - Main Dashboard with Analytics and Real Data
class HomeTabScreenEnhanced extends StatefulWidget {
  const HomeTabScreenEnhanced({super.key});

  @override
  State<HomeTabScreenEnhanced> createState() => _HomeTabScreenEnhancedState();
}

class _HomeTabScreenEnhancedState extends State<HomeTabScreenEnhanced>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _orderService = OrderService();
  bool _isLoading = true;
  bool _showAnalyticsView = true;
  bool _showPending = true;

  List<Order> _pendingOrders = [];
  List<Order> _completedOrders = [];
  int _totalCans = 0;
  double _totalEarnings = 0.0;

  // Analytics data
  List<Map<String, dynamic>> _revenueData = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _customerInsights = [];
  Map<String, dynamic> _quickStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _orderService.getTodayOrders(status: 'pending'),
        _orderService.getTodayOrders(status: 'completed'),
        _orderService.getDailySummary(),
        _generateAnalyticsData(),
      ]);

      setState(() {
        _pendingOrders = results[0] as List<Order>;
        _completedOrders = results[1] as List<Order>;
        final summary = results[2] as Map<String, dynamic>;
        _totalCans = summary['totalCans'] ?? 0;
        _totalEarnings = summary['totalEarnings'] ?? 0.0;

        final analytics = results[3] as Map<String, dynamic>;
        _revenueData = analytics['revenueData'] as List<Map<String, dynamic>>;
        _topProducts = analytics['topProducts'] as List<Map<String, dynamic>>;
        _customerInsights = analytics['customerInsights'] as List<Map<String, dynamic>>;
        _quickStats = analytics['quickStats'] as Map<String, dynamic>;

        _isLoading = false;
      });

      print('✅ Loaded ${_pendingOrders.length} pending, ${_completedOrders.length} completed orders');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _generateAnalyticsData() async {
    // Mock analytics data - In real implementation, this would come from the API
    final now = DateTime.now();

    // Generate 7-day revenue data
    final revenueData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return {
        'date': DateFormat('yyyy-MM-dd').format(date),
        'revenue': 800 + (index * 150) + (index % 2 * 200), // Mock revenue
      };
    });

    // Mock top products
    final topProducts = [
      {'name': 'AquaPure 20L', 'quantity': 45},
      {'name': 'FreshSpring 20L', 'quantity': 38},
      {'name': 'CrystalClear 20L', 'quantity': 32},
      {'name': 'PureDrop 20L', 'quantity': 28},
      {'name': 'AquaFresh 20L', 'quantity': 25},
    ];

    // Mock customer insights
    final customerInsights = [
      {
        'name': 'Rahul Sharma',
        'lastOrder': '2 hours ago',
        'totalOrders': 12,
        'totalSpent': 2400.0,
      },
      {
        'name': 'Priya Patel',
        'lastOrder': '5 hours ago',
        'totalOrders': 8,
        'totalSpent': 1600.0,
      },
      {
        'name': 'Amit Kumar',
        'lastOrder': '1 day ago',
        'totalOrders': 1,
        'totalSpent': 200.0,
      },
      {
        'name': 'Sneha Reddy',
        'lastOrder': '2 days ago',
        'totalOrders': 15,
        'totalSpent': 3000.0,
      },
      {
        'name': 'Vikram Singh',
        'lastOrder': '3 days ago',
        'totalOrders': 6,
        'totalSpent': 1200.0,
      },
    ];

    // Mock quick stats
    final quickStats = {
      'totalCustomers': 127,
      'customerGrowth': 12.5,
      'avgOrderValue': 350.0,
      'orderValueGrowth': -5.2,
      'deliveryRate': 98.5,
      'deliveryGrowth': 2.1,
      'totalRevenue': 12500.0,
      'revenueGrowth': 18.3,
      'cancellationRate': 3.2,
      'cancellationGrowth': -1.5,
    };

    return {
      'revenueData': revenueData,
      'topProducts': topProducts,
      'customerInsights': customerInsights,
      'quickStats': quickStats,
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM yyyy').format(now);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: AppTheme.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            _showAnalyticsView ? "Analytics Dashboard" : "Today's Deliveries",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.white.withValues(alpha: 0.9),
                                ),
                          ),
                          Text(
                            dateStr,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // View Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showAnalyticsView = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _showAnalyticsView
                                    ? AppTheme.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                'Analytics',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _showAnalyticsView
                                      ? AppTheme.primaryBlue
                                      : AppTheme.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showAnalyticsView = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_showAnalyticsView
                                    ? AppTheme.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                'Orders',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_showAnalyticsView
                                      ? AppTheme.primaryBlue
                                      : AppTheme.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_showAnalyticsView) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _showDeliveryBreakdown,
                            child: _buildSummaryCard(
                              context,
                              '$_totalCans',
                              'To be delivered',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            'Rs. ${_totalEarnings.toStringAsFixed(0)}',
                            'Earnings',
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Content Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _showAnalyticsView ? _buildAnalyticsView() : _buildOrdersView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Overview
          _buildPerformanceOverview(),
          const SizedBox(height: 24),

          // Quick Stats Grid
          QuickStatsGrid(
            cards: [
              QuickStatsCard(
                title: 'Total Customers',
                value: '${_quickStats['totalCustomers']}',
                changePercentage: _quickStats['customerGrowth'],
                isPositiveChange: (_quickStats['customerGrowth'] as double) > 0,
                icon: Icons.people_outline,
                iconColor: AppTheme.primaryBlue,
              ),
              QuickStatsCard(
                title: 'Avg Order Value',
                value: 'Rs.${(_quickStats['avgOrderValue'] as double).toStringAsFixed(0)}',
                changePercentage: _quickStats['orderValueGrowth'],
                isPositiveChange: (_quickStats['orderValueGrowth'] as double) > 0,
                icon: Icons.receipt_long_outlined,
                iconColor: AppTheme.successGreen,
              ),
              QuickStatsCard(
                title: 'Total Revenue',
                value: 'Rs.${(_quickStats['totalRevenue'] as double).toStringAsFixed(0)}',
                changePercentage: _quickStats['revenueGrowth'],
                isPositiveChange: (_quickStats['revenueGrowth'] as double) > 0,
                icon: Icons.trending_up_outlined,
                iconColor: AppTheme.warningOrange,
              ),
              QuickStatsCard(
                title: 'Delivery Rate',
                value: '${(_quickStats['deliveryRate'] as double).toStringAsFixed(1)}%',
                changePercentage: _quickStats['deliveryGrowth'],
                isPositiveChange: (_quickStats['deliveryGrowth'] as double) > 0,
                icon: Icons.local_shipping_outlined,
                iconColor: AppTheme.errorRed,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Range Selector
          DateRangeSelector(
            onRangeChanged: (rangeType, startDate, endDate) {
              // Handle date range change
              _loadData();
            },
          ),
          const SizedBox(height: 24),

          // Revenue Chart
          RevenueTrendChart(
            data: _revenueData,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),

          // Top Products
          TopProductsChart(
            data: _topProducts,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),

          // Customer Insights
          CustomerInsightsCard(
            customers: _customerInsights,
            isLoading: _isLoading,
            onViewAll: () {
              // Navigate to all customers
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrendCard(
                  'Weekly Trend',
                  '+15.3%',
                  true,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendCard(
                  'Monthly Trend',
                  '+8.7%',
                  true,
                  Icons.show_chart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, String percentage, bool isPositive, IconData icon) {
    final color = isPositive ? AppTheme.successGreen : AppTheme.errorRed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  percentage,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryBlue,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingOrders.length}',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Pending'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_completedOrders.length}',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Completed'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(_pendingOrders, true),
              _buildOrdersList(_completedOrders, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(List<Order> orders, bool isPending) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.inbox_outlined : Icons.check_circle_outline,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending orders' : 'No completed orders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildOrderCard(context, orders[index], isPending),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.white.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, bool isPending) {
    final customer = order.customer;
    if (customer == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mediumGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined,
                  size: 16, color: AppTheme.warningOrange),
              const SizedBox(width: 4),
              Text(
                order.timeSlot,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.warningOrange,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.errorRed),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.fullAddress,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.call, color: AppTheme.white, size: 20),
                  onPressed: () => _makePhoneCall(customer.phone),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Order Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.product?.name ?? 'Product'),
                          Text(
                            'x ${item.quantity}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Rs.${order.totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showUpdateStatusModal(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkGray,
                ),
                child: const Text('Update Status'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showUpdateStatusModal(BuildContext context, Order order) {
    showUpdateStatusModal(
      context: context,
      order: order,
      onUpdated: () {
        _loadData();
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  void _showDeliveryBreakdown() {
    // Calculate breakdown by product/brand
    final Map<String, int> productBreakdown = {};

    for (final order in _pendingOrders) {
      for (final item in order.items) {
        final productName = item.product?.name ?? 'Unknown Product';
        productBreakdown[productName] =
            (productBreakdown[productName] ?? 0) + item.quantity;
      }
    }

    if (productBreakdown.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products to deliver today'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Breakdown',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cans to be delivered today by brand',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: productBreakdown.length,
                itemBuilder: (context, index) {
                  final entry = productBreakdown.entries.elementAt(index);
                  final productName = entry.key;
                  final quantity = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.mediumGray),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.water_drop_rounded,
                                    color: AppTheme.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    productName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$quantity cans',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Close'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}