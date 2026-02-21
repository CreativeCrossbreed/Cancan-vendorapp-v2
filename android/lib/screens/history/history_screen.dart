import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../home/widgets/app_drawer.dart';

/// History Screen - View completed and cancelled orders
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _orderService = OrderService();
  bool _isLoading = true;
  bool _showCompleted = true;

  List<Order> _completedOrders = [];
  List<Order> _cancelledOrders = [];

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait<dynamic>([
        _orderService.getOrdersByDate(date: _selectedDate, status: 'completed'),
        _orderService.getOrdersByDate(date: _selectedDate, status: 'cancelled'),
      ]);

      setState(() {
        _completedOrders = results[0];
        _cancelledOrders = results[1];
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate:
          DateTime.now().subtract(const Duration(days: 90)), // Last 3 months
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: AppTheme.white,
              surface: AppTheme.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData();
  }

  void _goToNextDay() {
    if (_selectedDate
        .isBefore(DateTime.now().subtract(const Duration(hours: 24)))) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _loadData();
    }
  }

  bool _isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _isToday()
        ? 'Today, ${DateFormat('d MMM yyyy').format(_selectedDate)}'
        : DateFormat('EEEE, d MMM yyyy').format(_selectedDate);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Delivery History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date Navigator
          Container(
            color: AppTheme.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _goToPreviousDay,
                  icon: const Icon(Icons.chevron_left, color: AppTheme.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.white.withValues(alpha: 0.2),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.white,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!_isToday()) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.warningOrange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Past',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isToday() ? null : _goToNextDay,
                  icon: const Icon(Icons.chevron_right, color: AppTheme.white),
                  style: IconButton.styleFrom(
                    backgroundColor: _isToday()
                        ? AppTheme.white.withValues(alpha: 0.1)
                        : AppTheme.white.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),

          // Tab Selector
          Container(
            color: AppTheme.primaryBlue,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildTab(_completedOrders.length, 'Completed',
                      _showCompleted, true),
                  const SizedBox(width: 16),
                  _buildTab(_cancelledOrders.length, 'Cancelled',
                      !_showCompleted, false),
                ],
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildOrdersList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int count, String label, bool isActive, bool isCompleted) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showCompleted = isCompleted),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.white
                : AppTheme.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isCompleted
                          ? AppTheme.successGreen
                          : AppTheme.errorRed)
                      : AppTheme.mediumGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? AppTheme.textPrimary
                      : AppTheme.white.withValues(alpha: 0.7),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    final orders = _showCompleted ? _completedOrders : _cancelledOrders;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showCompleted
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              _showCompleted ? 'No completed orders' : 'No cancelled orders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _isToday()
                  ? 'on this day'
                  : 'on ${DateFormat('d MMM yyyy').format(_selectedDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildOrderCard(orders[index]),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final customer = order.customer;
    if (customer == null) return const SizedBox();

    final statusColor =
        order.status == 'completed' ? AppTheme.successGreen : AppTheme.errorRed;
    final statusBg = order.status == 'completed'
        ? AppTheme.completedBg
        : AppTheme.cancelledBg;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      order.status == 'completed'
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.status == 'completed' ? 'Completed' : 'Cancelled',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (order.paymentStatus == 'paid')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Paid',
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Unpaid',
                    style: TextStyle(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Customer Name
          Text(
            customer.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),

          // Address
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  customer.fullAddress,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Order Items
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.product?.name ?? 'Product',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'x ${item.quantity}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              )),

          const Divider(height: 20),

          // Total and Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs.${order.totalAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    order.timeSlot,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
