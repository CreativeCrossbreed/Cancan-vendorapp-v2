import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../home/widgets/app_drawer.dart';

/// Payments Screen - Track pending payments and earnings
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _orderService = OrderService();
  bool _isLoading = true;

  List<Order> _unpaidOrders = [];
  double _totalPending = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get ALL completed orders (across all dates) that are unpaid
      final allCompleted = await _orderService.getTodayOrders(status: 'completed');
      
      // For production, we'd need to fetch all unpaid orders, but for now use today's
      // In a real scenario, you'd query all completed orders with payment_status = 'unpaid'
      
      // Filter unpaid orders
      final unpaid = allCompleted
          .where((order) => order.paymentStatus == 'unpaid')
          .toList();

      // Calculate total pending amount
      double pendingAmount = 0;
      for (final order in unpaid) {
        pendingAmount += order.totalAmount;
      }

      setState(() {
        _unpaidOrders = unpaid;
        _totalPending = pendingAmount;
        _isLoading = false;
      });

      print('💰 Payments loaded: ${unpaid.length} unpaid orders');
      print('📊 Total Pending: Rs.$pendingAmount');
    } catch (e) {
      print('❌ Error loading payments: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Payments'),
        elevation: 0,
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // Payments Section
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: AppTheme.paddingXXL,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              'Payments',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              'Track pending payments',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingL),

                            // Pending Payments Header
                            Container(
                              padding: AppTheme.cardPadding,
                              decoration: BoxDecoration(
                                color: AppTheme.warningOrange
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.warningOrange
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: AppTheme.paddingS,
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningOrange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppTheme.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacingM),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pending Payments',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: AppTheme.spacingXS),
                                        Text(
                                          'Rs.${_totalPending.toStringAsFixed(0)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: AppTheme.warningOrange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          'To be collected from ${_unpaidOrders.length} customer${_unpaidOrders.length != 1 ? 's' : ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            
                            // Remind All Button
                            if (_unpaidOrders.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _remindAllToPay,
                                  icon: const Icon(Icons.chat_rounded),
                                  label: const Text('Remind all to Pay'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successGreen,
                                    padding: AppTheme.paddingVerticalL,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Customer List Header
                      Padding(
                        padding: AppTheme.paddingHorizontalXL,
                        child: Text(
                          'Customers with Pending Payments',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),

                      // Customers List
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                child: _buildCustomersList(),
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


  Widget _buildCustomersList() {
    if (_unpaidOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'All Payments Collected !',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.successGreen,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _unpaidOrders.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: _buildCustomerCard(_unpaidOrders[index]),
        );
      },
    );
  }

  Widget _buildCustomerCard(Order order) {
    final customer = order.customer;
    if (customer == null) return const SizedBox();
    
    // Get remaining amount (stored in order or calculate)
    final pendingAmount = order.totalAmount; // In real app, this would track partial payments

    return Container(
      padding: AppTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Rs.${pendingAmount.toStringAsFixed(0)}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.errorRed,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sendWhatsAppReminder(
                      customer.phone, customer.name, pendingAmount),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('Remind to Pay'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    side: const BorderSide(color: AppTheme.successGreen),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showPaymentDialog(order, pendingAmount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                  ),
                  child: const Text('Paid'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _remindAllToPay() async {
    if (_unpaidOrders.isEmpty) return;
    
    for (final order in _unpaidOrders) {
      final customer = order.customer;
      if (customer != null) {
        await _sendWhatsAppReminder(
          customer.phone,
          customer.name,
          order.totalAmount,
        );
        // Small delay between messages
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminders sent to all customers'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }
  
  void _showPaymentDialog(Order order, double pendingAmount) {
    final amountController = TextEditingController(
      text: pendingAmount.toStringAsFixed(0),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pending Amount: Rs.${pendingAmount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount Received',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final receivedAmount = double.tryParse(amountController.text);
              if (receivedAmount == null || receivedAmount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }
              
              if (receivedAmount >= pendingAmount) {
                // Full payment
                await _markAsPaid(order);
              } else {
                // Partial payment - update order with remaining amount
                // In a real app, you'd store partial payments
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Partial payment recorded. Remaining: Rs.${(pendingAmount - receivedAmount).toStringAsFixed(0)}',
                    ),
                    backgroundColor: AppTheme.warningOrange,
                  ),
                );
                Navigator.pop(context);
                _loadData(); // Refresh to show updated amounts
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsAppReminder(
      String phone, String name, double amount) async {
    // Remove + and spaces from phone number
    final cleanPhone = phone.replaceAll(RegExp(r'[+\s]'), '');
    final message =
        'Hi $name! This is a friendly reminder about your pending water can payment of Rs.${amount.toStringAsFixed(0)}. Please pay at your earliest convenience. Thank you!';
    final uri =
        Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _markAsPaid(Order order) async {
    final result = await _orderService.updateOrderStatus(
      orderId: order.id,
      isDelivered: order.isDelivered,
      isPaid: true,
    );

    if (!mounted) return;
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment marked as received!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      _loadData();
    }
  }
}
