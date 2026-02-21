import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/vacation_service.dart';
import '../home/widgets/app_drawer.dart';

/// Vacation Screen - Manage vacation mode and unavailability
class VacationScreen extends StatefulWidget {
  const VacationScreen({super.key});

  @override
  State<VacationScreen> createState() => _VacationScreenState();
}

class _VacationScreenState extends State<VacationScreen> {
  final _vacationService = VacationService();
  bool _isLoading = true;
  Map<String, dynamic> _vacationStatus = {};

  @override
  void initState() {
    super.initState();
    _loadVacationStatus();
  }

  Future<void> _loadVacationStatus() async {
    setState(() => _isLoading = true);

    try {
      final status = await _vacationService.getVacationStatus();
      setState(() {
        _vacationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnVacation = _vacationStatus['isOnVacation'] ?? false;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Vacation Mode'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVacationStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVacationStatusCard(isOnVacation),
                  const SizedBox(height: 32),
                  if (!isOnVacation) ...[
                    _buildSetupVacationCard(),
                    const SizedBox(height: 32),
                  ],
                  if (isOnVacation) ...[
                    _buildActiveVacationCard(),
                    const SizedBox(height: 32),
                    _buildExtendVacationCard(),
                    const SizedBox(height: 32),
                  ],
                  _buildVacationInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildVacationStatusCard(bool isOnVacation) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isOnVacation
            ? LinearGradient(
                colors: [AppTheme.warningOrange.withOpacity(0.1), AppTheme.warningOrange.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [AppTheme.successGreen.withOpacity(0.1), AppTheme.successGreen.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnVacation ? AppTheme.warningOrange.withOpacity(0.3) : AppTheme.successGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isOnVacation ? Icons.beach_access : Icons.check_circle,
            size: 64,
            color: isOnVacation ? AppTheme.warningOrange : AppTheme.successGreen,
          ),
          const SizedBox(height: 16),
          Text(
            isOnVacation ? 'Vacation Mode Active' : 'Available for Orders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isOnVacation ? AppTheme.warningOrange : AppTheme.successGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOnVacation
                ? 'Customers will see your vacation message'
                : 'You are currently accepting new orders',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isOnVacation ? AppTheme.warningOrange : AppTheme.successGreen,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupVacationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
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
            'Set Up Vacation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showVacationSetupDialog,
            icon: const Icon(Icons.event),
            label: const Text('Schedule Vacation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVacationCard() {
    final startDate = _vacationStatus['vacationStartDate'];
    final endDate = _vacationStatus['vacationEndDate'];
    final message = _vacationStatus['vacationMessage'] ?? 'Currently on vacation';
    final autoReplyEnabled = _vacationStatus['autoReplyEnabled'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningOrange.withOpacity(0.3)),
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
            'Current Vacation Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (startDate != null)
            _buildDetailRow('Start Date', _formatDate(startDate)),
          if (endDate != null)
            _buildDetailRow('End Date', _formatDate(endDate)),
          _buildDetailRow('Auto Reply', autoReplyEnabled ? 'Enabled' : 'Disabled'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Message:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _disableVacationMode,
              icon: const Icon(Icons.cancel),
              label: const Text('End Vacation Early'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtendVacationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
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
            'Need More Time?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Extend your vacation period if needed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showExtendVacationDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Extend Vacation'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.warningOrange),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacationInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'About Vacation Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            'Order Blocking',
            'Customers cannot place new orders while you\'re on vacation',
          ),
          _buildInfoItem(
            'Auto Reply',
            'Optional automatic response to customer inquiries',
          ),
          _buildInfoItem(
            'Status Visibility',
            'Your vacation status is visible to customers',
          ),
          _buildInfoItem(
            'Automatic End',
            'Vacation mode automatically ends on the selected date',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
               size: 20,
               color: AppTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showVacationSetupDialog() {
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final messageController = TextEditingController();
    bool autoReplyEnabled = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Schedule Vacation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Start Date',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      startDateController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: 'End Date',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      endDateController.text = DateFormat('yyyy-MM-dd').format(date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Vacation Message',
                    hintText: 'Message shown to customers',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable Auto Reply'),
                  subtitle: const Text('Automatically respond to customer messages'),
                  value: autoReplyEnabled,
                  onChanged: (value) {
                    setState(() {
                      autoReplyEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (startDateController.text.isNotEmpty &&
                    endDateController.text.isNotEmpty) {
                  final startDate = DateTime.parse(startDateController.text);
                  final endDate = DateTime.parse(endDateController.text);
                  final message = messageController.text.isNotEmpty
                      ? messageController.text
                      : 'Currently on vacation';

                  final result = await _vacationService.enableVacationMode(
                    startDate: startDate,
                    endDate: endDate,
                    message: message,
                    enableAutoReply: autoReplyEnabled,
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success']
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                    ),
                  );

                  _loadVacationStatus();
                }
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendVacationDialog() {
    final newEndDateController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Vacation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newEndDateController,
              decoration: const InputDecoration(
                labelText: 'New End Date',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  newEndDateController.text = DateFormat('yyyy-MM-dd').format(date);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Updated Message (Optional)',
                hintText: 'New vacation message for customers',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              if (newEndDateController.text.isNotEmpty) {
                final newEndDate = DateTime.parse(newEndDateController.text);
                final updatedMessage = messageController.text.isNotEmpty
                    ? messageController.text
                    : null;

                final result = await _vacationService.extendVacationPeriod(
                  newEndDate: newEndDate,
                  updatedMessage: updatedMessage,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success']
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                  ),
                );

                _loadVacationStatus();
              }
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  void _disableVacationMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Vacation Early?'),
        content: const Text('Are you sure you want to end your vacation early? You will start receiving new orders immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('End Vacation'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _vacationService.disableVacationMode();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success']
              ? AppTheme.successGreen
              : AppTheme.errorRed,
        ),
      );

      _loadVacationStatus();
    }
  }
}