import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../utils/logger.dart';

/// Orders Screen - Simple, accessible delivery app-style interface
/// Optimized for illiterate users (Blinkit/Rapido/Zomato inspired)
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderService = OrderService();
  bool _isLoading = true;
  bool _showPending = true;

  List<Order> _pendingOrders = [];
  List<Order> _completedOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _orderService.getTodayOrders(status: 'pending'),
        _orderService.getTodayOrders(status: 'delivered'),
      ]);

      setState(() {
        _pendingOrders = results[0];
        _completedOrders = results[1];
        _isLoading = false;
      });

      AppLogger.i('Loaded ${_pendingOrders.length} pending, ${_completedOrders.length} completed orders');
    } catch (e) {
      AppLogger.e('Error loading orders: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMM').format(now);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(dateStr),
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            _buildTabSelector(),
                            Expanded(child: _buildOrdersList()),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String dateStr) {
    return Padding(
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
                    'Today\'s Orders',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.white.withValues(alpha: 0.9),
                        ),
                  ),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${_pendingOrders.length}',
                  'To Deliver',
                  AppTheme.warningOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '${_completedOrders.length}',
                  'Done',
                  AppTheme.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              _pendingOrders.length,
              'Pending',
              _showPending,
              true,
              AppTheme.warningOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTab(
              _completedOrders.length,
              'Completed',
              !_showPending,
              false,
              AppTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    int count,
    String label,
    bool isActive,
    bool isPending,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _showPending = isPending),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: isActive ? AppTheme.white : color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPending ? Icons.pending : Icons.check_circle,
                  size: 20,
                  color: isActive ? AppTheme.white : color,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isActive ? AppTheme.white : color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final orders = _showPending ? _pendingOrders : _completedOrders;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (_showPending ? AppTheme.warningOrange : AppTheme.successGreen).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showPending ? Icons.inventory_2_outlined : Icons.check_circle_outline,
                size: 64,
                color: _showPending ? AppTheme.warningOrange : AppTheme.successGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _showPending ? 'No pending orders' : 'No completed orders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _showPending ? 'All caught up!' : 'Start delivering to see orders here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildOrderCard(orders[index], _showPending),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, bool isPending) {
    final customer = order.customer;
    if (customer == null) return const SizedBox();

    // Calculate total cans
    final totalCans = order.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isPending ? AppTheme.warningOrange.withValues(alpha: 0.3) : AppTheme.successGreen.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isPending
                  ? AppTheme.warningOrange.withValues(alpha: 0.1)
                  : AppTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isPending ? AppTheme.warningOrange : AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPending ? Icons.pending_actions : Icons.check_circle,
                        size: 18,
                        color: AppTheme.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isPending ? 'PENDING' : 'DELIVERED',
                      style: TextStyle(
                        color: isPending ? AppTheme.warningOrange : AppTheme.successGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      order.timeSlot,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Customer info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BIG customer name
                Text(
                  customer.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Address with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppTheme.errorRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        customer.fullAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order details - Big cans display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Water drops visualization
                      Row(
                        children: [
                          ...List.generate(
                            totalCans.clamp(1, 5),
                            (index) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.water_drop,
                                size: 28,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          if (totalCans > 5)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '+$totalCans',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Amount
                      Column(
                        children: [
                          Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons row
                Row(
                  children: [
                    // CALL button - BIG and prominent
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => _makePhoneCall(customer.phone),
                          icon: const Icon(Icons.phone, size: 24),
                          label: const Text(
                            'CALL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                if (isPending) ...[
                  const SizedBox(width: 12),
                  // MARK DELIVERED button - BIG green
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsDelivered(order),
                        icon: const Icon(Icons.check_circle, size: 24),
                        label: const Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open phone'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _markAsDelivered(Order order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen),
            SizedBox(width: 12),
            Text('Mark as Delivered?'),
          ],
        ),
        content: Text(
          'Confirm delivery for ${order.customer?.name ?? 'this order'}?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'NO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'YES, DELIVERED',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _orderService.updateOrderStatus(
        orderId: order.id,
        status: 'delivered',
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.white),
                  SizedBox(width: 12),
                  Text('Order marked as delivered!'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
