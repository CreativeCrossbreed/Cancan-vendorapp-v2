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
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateFilterMode = 'today'; // 'today', 'specific', 'range'
  
  // Summary data
  int _totalCansDelivered = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      List<Order> completed = [];
      List<Order> cancelled = [];

      if (_dateFilterMode == 'range' && _startDate != null && _endDate != null) {
        // Load orders for date range
        DateTime current = _startDate!;
        while (current.isBefore(_endDate!) || current.isAtSameMomentAs(_endDate!)) {
          final dayCompleted = await _orderService.getOrdersByDate(
            date: current,
            status: 'completed',
          );
          final dayCancelled = await _orderService.getOrdersByDate(
            date: current,
            status: 'cancelled',
          );
          completed.addAll(dayCompleted);
          cancelled.addAll(dayCancelled);
          current = current.add(const Duration(days: 1));
        }
      } else {
        // Load orders for specific date
        final results = await Future.wait([
          _orderService.getOrdersByDate(date: _selectedDate, status: 'completed'),
          _orderService.getOrdersByDate(date: _selectedDate, status: 'cancelled'),
        ]);
        completed = results[0];
        cancelled = results[1];
      }

      // Calculate totals
      int totalCans = 0;
      double totalEarnings = 0.0;
      
      for (final order in completed) {
        totalEarnings += order.totalAmount;
        for (final item in order.items) {
          totalCans += item.quantity;
        }
      }

      setState(() {
        _completedOrders = completed;
        _cancelledOrders = cancelled;
        _totalCansDelivered = totalCans;
        _totalEarnings = totalEarnings;
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
        _dateFilterMode = 'specific';
      });
      _loadData();
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
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

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _dateFilterMode = 'range';
        _selectedDate = picked.start;
      });
      _loadData();
    }
  }

  void _setDateFilterMode(String mode) {
    setState(() {
      _dateFilterMode = mode;
      if (mode == 'today') {
        _selectedDate = DateTime.now();
        _startDate = null;
        _endDate = null;
      }
    });
    _loadData();
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
    String dateStr;
    if (_dateFilterMode == 'range' && _startDate != null && _endDate != null) {
      dateStr = '${DateFormat('d MMM').format(_startDate!)} - ${DateFormat('d MMM yyyy').format(_endDate!)}';
    } else if (_isToday()) {
      dateStr = 'Today, ${DateFormat('d MMM yyyy').format(_selectedDate)}';
    } else {
      dateStr = DateFormat('EEEE, d MMM yyyy').format(_selectedDate);
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Delivery History'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: _setDateFilterMode,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'today',
                child: Text('Today'),
              ),
              const PopupMenuItem(
                value: 'specific',
                child: Text('Specific Day'),
              ),
              const PopupMenuItem(
                value: 'range',
                child: Text('Date Range'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Navigator
          Container(
            color: AppTheme.primaryBlue,
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingL, vertical: AppTheme.spacingM),
            child: Row(
              children: [
                if (_dateFilterMode != 'range')
                  IconButton(
                    onPressed: _goToPreviousDay,
                    icon: const Icon(Icons.chevron_left, color: AppTheme.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.white.withValues(alpha: 0.2),
                    ),
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: InkWell(
                    onTap: _dateFilterMode == 'range' ? _selectDateRange : _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppTheme.white,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Flexible(
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_dateFilterMode == 'range')
                            const SizedBox(width: AppTheme.spacingS)
                          else if (!_isToday()) ...[
                            const SizedBox(width: AppTheme.spacingS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.warningOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Past',
                                style: TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 11,
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
                if (_dateFilterMode != 'range')
                  IconButton(
                    onPressed: _isToday() ? null : _goToNextDay,
                    icon: const Icon(Icons.chevron_right, color: AppTheme.white),
                    style: IconButton.styleFrom(
                      backgroundColor: _isToday()
                          ? AppTheme.white.withValues(alpha: 0.1)
                          : AppTheme.white.withValues(alpha: 0.2),
                    ),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),

          // Summary Cards
          Container(
            color: AppTheme.primaryBlue,
            child: Column(
              children: [
                // Summary Cards
                if (_dateFilterMode != 'range' || (_startDate != null && _endDate != null))
                  Padding(
                    padding: EdgeInsets.fromLTRB(AppTheme.spacingL, 0, AppTheme.spacingL, AppTheme.spacingL),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            '$_totalCansDelivered',
                            'Total Cans Delivered',
                            Icons.local_shipping_rounded,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildSummaryCard(
                            'Rs.${_totalEarnings.toStringAsFixed(0)}',
                            'Total Earnings',
                            Icons.currency_rupee_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Tab Selector
          Container(
            color: AppTheme.white,
            padding: EdgeInsets.fromLTRB(AppTheme.spacingL, AppTheme.spacingL, AppTheme.spacingL, 0),
            child: Row(
              children: [
                  _buildTab(_completedOrders.length, 'Completed',
                      _showCompleted, true),
                  const SizedBox(width: AppTheme.spacingL),
                  _buildTab(_cancelledOrders.length, 'Cancelled',
                      !_showCompleted, false),
              ],
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

  Widget _buildSummaryCard(String value, String label, IconData icon) {
    return Container(
      padding: AppTheme.paddingM,
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.white, size: 20),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.white.withValues(alpha: 0.9),
                  fontSize: 11,
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
                ? (isCompleted
                    ? AppTheme.successGreen.withValues(alpha: 0.1)
                    : AppTheme.errorRed.withValues(alpha: 0.1))
                : AppTheme.lightGray,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(
                    color: isCompleted
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    width: 2,
                  )
                : null,
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
                      : AppTheme.textSecondary,
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
            const SizedBox(height: AppTheme.spacingL),
            Text(
              _showCompleted ? 'No completed orders' : 'No cancelled orders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _dateFilterMode == 'range' && _startDate != null && _endDate != null
                  ? 'from ${DateFormat('d MMM').format(_startDate!)} to ${DateFormat('d MMM yyyy').format(_endDate!)}'
                  : _isToday()
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
      padding: AppTheme.screenPadding,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
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

    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Status Badge (only for completed orders)
          if (order.status == 'completed')
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.paymentStatus == 'paid')
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppTheme.spacingM, vertical: 6),
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
          const SizedBox(height: AppTheme.spacingM),

          // Customer Name
          Text(
            customer.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingXS),

          // Address
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: AppTheme.spacingXS),
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
          const SizedBox(height: AppTheme.spacingM),

          // Order Items
                ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
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

          const Divider(height: AppTheme.spacingXL),

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
