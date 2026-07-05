import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
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
  final _searchController = TextEditingController();
  bool _isLoading = true;

  // Filters by payment status, not delivery status — cans/earnings totals
  // moved to Analytics, and "Completed/Cancelled" tabs are replaced with
  // "All/Unpaid/Paid" since that's what vendors actually need to track here.
  String _paymentFilter = 'all'; // 'all', 'unpaid', 'paid'
  List<Order> _deliveredOrders = [];

  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateFilterMode = 'today'; // 'today', 'specific', 'range'

  bool _isDeliveredStatus(String status) => status == 'completed' || status == 'delivered';

  List<Order> get _filteredOrders {
    var orders = _deliveredOrders;

    if (_paymentFilter == 'paid') {
      orders = orders.where((o) => o.paymentStatus == 'paid').toList();
    } else if (_paymentFilter == 'unpaid') {
      orders = orders.where((o) => o.paymentStatus != 'paid').toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      orders = orders.where((o) {
        final customer = o.customer;
        if (customer == null) return false;
        return customer.name.toLowerCase().contains(query) || customer.phone.contains(query);
      }).toList();
    }

    return orders;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      List<Order> delivered = [];

      if (_dateFilterMode == 'range' &&
          _startDate != null &&
          _endDate != null) {
        // Load orders for date range
        DateTime current = _startDate!;
        while (current.isBefore(_endDate!) ||
            current.isAtSameMomentAs(_endDate!)) {
          final dayDelivered = await _orderService.getOrdersByDate(
            date: current,
            status: 'delivered',
          );
          delivered.addAll(dayDelivered);
          current = current.add(const Duration(days: 1));
        }
      } else {
        // Load orders for specific date
        delivered = await _orderService.getOrdersByDate(
            date: _selectedDate, status: 'delivered');
      }

      setState(() {
        _deliveredOrders = delivered;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading history: $e');
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
        color: AppTheme.white,
        child: SafeArea(
          child: Column(
            children: [
              // Flat minimal header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery History',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          fullDateStr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
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
                            // Payment status filter — carousel of All/Unpaid/Paid chips.
                            _buildPaymentFilterCarousel(),
                            const SizedBox(height: AppTheme.spacingM),
                            // Search by customer name or phone number.
                            TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search by name or mobile number',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
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

  Widget _buildPaymentFilterCarousel() {
    final filters = [
      ('all', 'All', _deliveredOrders.length, AppTheme.primaryBlue),
      ('unpaid', 'Unpaid', _deliveredOrders.where((o) => o.paymentStatus != 'paid').length, AppTheme.errorRed),
      ('paid', 'Paid', _deliveredOrders.where((o) => o.paymentStatus == 'paid').length, AppTheme.successGreen),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingS),
        itemBuilder: (context, index) {
          final (value, label, count, color) = filters[index];
          final isActive = _paymentFilter == value;

          return GestureDetector(
            onTap: () => setState(() => _paymentFilter = value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? color.withValues(alpha: 0.1) : AppTheme.lightGray,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? color : AppTheme.mediumGray, width: isActive ? 2 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? color : AppTheme.textSecondary,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isActive ? color : AppTheme.mediumGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(color: AppTheme.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    final orders = _filteredOrders;

    if (orders.isEmpty) {
      final hasSearch = _searchController.text.trim().isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.inbox_outlined,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              hasSearch
                  ? 'No matching orders'
                  : switch (_paymentFilter) {
                      'paid' => 'No paid orders',
                      'unpaid' => 'No unpaid orders',
                      _ => 'No delivered orders',
                    },
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
                    AppConstants.formatTimeSlot(order.timeSlot),
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
