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

  bool _isDeliveredStatus(String status) => status == 'completed' || status == 'delivered';

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

      if (_dateFilterMode == 'range' &&
          _startDate != null &&
          _endDate != null) {
        // Load orders for date range
        DateTime current = _startDate!;
        while (current.isBefore(_endDate!) ||
            current.isAtSameMomentAs(_endDate!)) {
          final dayCompleted = await _orderService.getOrdersByDate(
            date: current,
            status: 'delivered',
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
          _orderService.getOrdersByDate(
              date: _selectedDate, status: 'delivered'),
          _orderService.getOrdersByDate(
              date: _selectedDate, status: 'cancelled'),
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

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData();
  }

  void _goToNextDay() {
    final now = DateTime.now();
    if (_selectedDate.isBefore(DateTime(now.year, now.month, now.day))) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _loadData();
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
        _dateFilterMode = _isToday()
            ? 'today'
            : 'today'; // Keep in today mode but allow viewing past dates
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

  bool _isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    // Date string for selector (no day name)
    String dateStr;
    if (_dateFilterMode == 'range' && _startDate != null && _endDate != null) {
      dateStr =
          '${DateFormat('d MMM').format(_startDate!)} - ${DateFormat('d MMM yyyy').format(_endDate!)}';
    } else {
      dateStr = DateFormat('d MMM yyyy').format(_selectedDate);
    }

    // Full date string with day for header
    String fullDateStr;
    if (_dateFilterMode == 'range' && _startDate != null && _endDate != null) {
      fullDateStr =
          '${DateFormat('d MMM').format(_startDate!)} - ${DateFormat('d MMM yyyy').format(_endDate!)}';
    } else if (_isToday()) {
      fullDateStr = 'Today, ${DateFormat('d MMM yyyy').format(_selectedDate)}';
    } else {
      fullDateStr =
          '${DateFormat('EEEE').format(_selectedDate)}, ${DateFormat('d MMM yyyy').format(_selectedDate)}';
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: AppTheme.paddingXXL,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Isolated hamburger icon
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: AppTheme.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        // Center title/subtitle
                        Column(
                          children: [
                            Text(
                              'Delivery History',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        AppTheme.white.withValues(alpha: 0.9),
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              fullDateStr,
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
                        // Balance spacing
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXXL),
                    // Summary Cards
                    if (_dateFilterMode != 'range' ||
                        (_startDate != null && _endDate != null))
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              '$_totalCansDelivered',
                              'Total Cans Delivered',
                              Icons.water_drop_rounded,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: _buildSummaryCard(
                              'Rs. ${_totalEarnings.toStringAsFixed(0)}',
                              'Total Earnings',
                              Icons.payments_rounded,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Content Area with white background
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Tab Selector and Date Navigator
                      Container(
                        padding: EdgeInsets.fromLTRB(
                            AppTheme.spacingL,
                            AppTheme.spacingXXL,
                            AppTheme.spacingL,
                            AppTheme.spacingM),
                        child: Column(
                          children: [
                            // Tabs
                            Row(
                              children: [
                                _buildTab(_completedOrders.length, 'Completed',
                                    _showCompleted, true),
                                const SizedBox(width: AppTheme.spacingL),
                                _buildTab(_cancelledOrders.length, 'Cancelled',
                                    !_showCompleted, false),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            // Date Navigator and Filter
                            Row(
                              children: [
                                if (_dateFilterMode != 'range')
                                  IconButton(
                                    onPressed: _goToPreviousDay,
                                    icon: const Icon(Icons.chevron_left,
                                        size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.lightGray,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 40),
                                const SizedBox(width: AppTheme.spacingS),
                                Expanded(
                                  child: InkWell(
                                    onTap: _dateFilterMode == 'range'
                                        ? _selectDateRange
                                        : _selectDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightGray,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppTheme.mediumGray
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 16,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          const SizedBox(
                                              width: AppTheme.spacingS),
                                          Text(
                                            dateStr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                if (_dateFilterMode != 'range')
                                  IconButton(
                                    onPressed: _isToday() ? null : _goToNextDay,
                                    icon: const Icon(Icons.chevron_right,
                                        size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.lightGray,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 40),
                                const SizedBox(width: AppTheme.spacingS),
                                // Filter Button
                                PopupMenuButton<String>(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightGray,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.mediumGray
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.filter_list_rounded,
                                      color: AppTheme.primaryBlue,
                                      size: 18,
                                    ),
                                  ),
                                  onSelected: _setDateFilterMode,
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'today',
                                      child: Text('Today'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'range',
                                      child: Text('Date Range'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        height: 1,
                        color: AppTheme.mediumGray.withValues(alpha: 0.3),
                      ),

                      // Orders List Container
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
                ),
              ),
            ],
          ),
        ),
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
      child: Row(
        children: [
          Icon(icon, color: AppTheme.white, size: 24),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int count, String label, bool isActive, bool isCompleted) {
    // Determine colors based on tab type
    final activeColor = isCompleted ? AppTheme.successGreen : AppTheme.errorRed;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showCompleted = isCompleted),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.1)
                : activeColor.withValues(
                    alpha: 0.15), // More visible when inactive
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(
                    color: activeColor,
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
                      ? activeColor
                      : activeColor.withValues(
                          alpha: 0.5), // More visible for inactive badge
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
                  color:
                      isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
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
              _dateFilterMode == 'range' &&
                      _startDate != null &&
                      _endDate != null
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
        _isDeliveredStatus(order.status) ? AppTheme.successGreen : AppTheme.errorRed;

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
          // Time Slot and Payment Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 16, color: AppTheme.warningOrange),
                  const SizedBox(width: AppTheme.spacingXS),
                  Text(
                    order.timeSlot,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningOrange,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              // Payment Status Badge (only for completed orders)
              if (_isDeliveredStatus(order.status))
                if (order.paymentStatus == 'paid')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Paid',
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Unpaid',
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
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

          // Total Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
