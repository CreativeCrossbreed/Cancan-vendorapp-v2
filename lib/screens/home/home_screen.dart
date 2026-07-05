import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/order_service.dart';
import '../../services/vendor_service.dart';
import '../../models/order.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../utils/localization_extension.dart';
import 'widgets/update_status_modal.dart';
import 'widgets/app_drawer.dart';
import '../history/history_screen.dart';
import '../payments/payments_screen.dart';
import '../inventory/inventory_screen.dart';

/// Home Screen - Main Dashboard with Bottom Navigation
class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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
        currentScreen = const HomeTabScreen();
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
        currentScreen = const HomeTabScreen();
    }

    return Scaffold(
      drawer: const AppDrawer(),
      body: currentScreen,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

/// Home Tab - Main Dashboard with Real Data
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final _orderService = OrderService();
  final _vendorService = VendorService();
  bool _isLoading = true;

  static const int _carouselDayCount = 7; // Today + Tomorrow + next 5 days
  late final DateTime _today = DateTime.now();
  late DateTime _selectedDate = DateTime(_today.year, _today.month, _today.day);

  List<Order> _pendingOrders = [];
  int _totalCans = 0;
  bool _isVendorReady = true;
  String _vendorReadinessMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onDateSelected(DateTime date) {
    if (_isSameDay(date, _selectedDate)) return;
    setState(() => _selectedDate = date);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _orderService.getOrdersByDate(date: _selectedDate, status: 'pending'),
        _orderService.getDailySummaryForDate(_selectedDate),
        _vendorService.getVendorReadinessStatus(),
      ]);

      setState(() {
        _pendingOrders = results[0] as List<Order>;
        final summary = results[1] as Map<String, dynamic>;
        final readiness = results[2] as Map<String, dynamic>;
        _totalCans = summary['totalCans'] ?? 0;
        _isVendorReady = readiness['isReady'] ?? false;
        _vendorReadinessMessage = readiness['message'] ?? '';
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${_pendingOrders.length} pending orders');
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('deliveries_for'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildDateCarousel(context),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: _showDeliveryBreakdown,
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildSummaryCard(
                          context,
                          '$_totalCans',
                          context.tr('to_be_delivered'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            if (!_isLoading && !_isVendorReady)
              Padding(
                padding: AppTheme.screenPaddingHorizontal,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningOrange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          _vendorReadinessMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
    );
  }

  Widget _buildOrdersList() {
    if (_pendingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              context.tr('no_pending_orders'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppTheme.screenPaddingHorizontal,
      itemCount: _pendingOrders.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
          child: _buildOrderCard(context, _pendingOrders[index]),
        );
      },
    );
  }

  Widget _buildDateCarousel(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _carouselDayCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingS),
        itemBuilder: (context, index) {
          final date = _today.add(Duration(days: index));
          final isSelected = _isSameDay(date, _selectedDate);
          final dayLabel = index == 0
              ? context.tr('today_label')
              : index == 1
                  ? context.tr('tomorrow_label')
                  : DateFormat('EEE').format(date);
          final dateLabel = DateFormat('d MMM').format(date);

          return GestureDetector(
            onTap: () => _onDateSelected(date),
            child: Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.mediumGray,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
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

  Widget _buildSummaryCard(BuildContext context, String value, String label) {
    return Container(
      padding: AppTheme.paddingXL,
      constraints: const BoxConstraints(minHeight: 96),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mediumGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_shipping_rounded, color: AppTheme.primaryBlueDark),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final customer = order.customer;
    if (customer == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
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
          const SizedBox(height: AppTheme.spacingM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _openGoogleMaps(customer.fullAddress),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.mediumGray.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 14, color: AppTheme.errorRed),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                customer.fullAddress,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.call,
                          color: AppTheme.white, size: 20),
                      onPressed: () => _makePhoneCall(customer.phone),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
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
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      context.tr('order_details'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.product?.name ?? context.tr('product'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingXS),
                                Text(
                                  'Rs. ${item.unitPrice.toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'x ${item.quantity}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )),
                const Divider(height: AppTheme.spacingXL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('total_amount'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Rs. ${order.totalAmount.toStringAsFixed(0)}',
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
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUpdateStatusModal(context, order),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Update Status'),
            ),
          ),
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
    // externalApplication forces the native Phone dialer. Without it, iOS
    // can route tel: links through a universal-link handler that opens
    // FaceTime instead of the Phone app for numbers it associates with
    // an Apple ID/FaceTime-enabled contact.
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _openGoogleMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
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
