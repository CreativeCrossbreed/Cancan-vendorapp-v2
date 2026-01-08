import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/order.dart';
import '../../../services/order_service.dart';

/// Update Status Modal - Mark order as delivered/paid
class UpdateStatusModal extends StatefulWidget {
  final Order order;
  final VoidCallback onUpdated;

  const UpdateStatusModal({
    super.key,
    required this.order,
    required this.onUpdated,
  });

  @override
  State<UpdateStatusModal> createState() => _UpdateStatusModalState();
}

class _UpdateStatusModalState extends State<UpdateStatusModal> {
  final _orderService = OrderService();
  bool _isDelivered = false;
  bool _isPaid = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Update Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Customer Info
          Text(
            widget.order.customer?.name ?? 'Customer',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                ),
          ),
          Text(
            'Order: ${widget.order.orderNumber}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Status Toggles
          _buildStatusToggle(
            title: 'Cash Paid',
            subtitle: 'Mark payment as received',
            value: _isPaid,
            onChanged: (value) => setState(() => _isPaid = value),
            icon: Icons.payments_outlined,
            color: AppTheme.successGreen,
          ),
          const SizedBox(height: 16),

          _buildStatusToggle(
            title: 'Delivered',
            subtitle: 'Mark order as delivered',
            value: _isDelivered,
            onChanged: (value) => setState(() => _isDelivered = value),
            icon: Icons.check_circle_outline,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 24),

          // Confirm Button
          ElevatedButton(
            onPressed: (_isLoading || !_isDelivered) ? null : _updateStatus,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryBlue,
              disabledBackgroundColor: AppTheme.mediumGray,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : const Text('Confirm'),
          ),

          // Safe area padding for bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildStatusToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.1) : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color : AppTheme.mediumGray,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? color : AppTheme.mediumGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus() async {
    if (!_isDelivered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mark "Delivered" to confirm'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _orderService.updateOrderStatus(
        orderId: widget.order.id,
        isDelivered: _isDelivered,
        isPaid: _isPaid,
      );

      if (!mounted) return;

      if (result['success']) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDelivered && _isPaid
                  ? 'Order marked as delivered and paid!'
                  : _isDelivered
                      ? 'Order marked as delivered!'
                      : 'Payment marked as received!',
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        // Trigger refresh in parent
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update status'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// Helper function to show the modal
void showUpdateStatusModal({
  required BuildContext context,
  required Order order,
  required VoidCallback onUpdated,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => UpdateStatusModal(
      order: order,
      onUpdated: onUpdated,
    ),
  );
}
