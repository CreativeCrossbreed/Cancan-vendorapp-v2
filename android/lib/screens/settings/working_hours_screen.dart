import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/vendor_service.dart';
import '../home/widgets/app_drawer.dart';
import '../../utils/logger.dart';

/// Working Hours Screen - Set business hours
class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  final _vendorService = VendorService();
  bool _isLoading = true;
  bool _isSaving = false;

  final Map<String, bool> _workingDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': false,
  };

  TimeOfDay _openTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    setState(() => _isLoading = true);
    try {
      final data = await _vendorService.getVendorProfile();
      if (data != null) {
        if (data['working_hours'] != null) {
          final hours = data['working_hours'] as Map<String, dynamic>;
          if (hours['open'] != null) {
            final openParts = hours['open'].toString().split(':');
            _openTime = TimeOfDay(
              hour: int.parse(openParts[0]),
              minute: int.parse(openParts[1]),
            );
          }
          if (hours['close'] != null) {
            final closeParts = hours['close'].toString().split(':');
            _closeTime = TimeOfDay(
              hour: int.parse(closeParts[0]),
              minute: int.parse(closeParts[1]),
            );
          }
        }
        if (data['working_days'] != null) {
          final days = List<String>.from(data['working_days'] as List);
          for (var day in _workingDays.keys) {
            _workingDays[day] = days.contains(day.toLowerCase());
          }
        }
      }
    } catch (e) {
      AppLogger.d('❌ Error loading working hours: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectOpenTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openTime,
    );
    if (picked != null) {
      setState(() => _openTime = picked);
    }
  }

  Future<void> _selectCloseTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _closeTime,
    );
    if (picked != null) {
      setState(() => _closeTime = picked);
    }
  }

  Future<void> _saveWorkingHours() async {
    setState(() => _isSaving = true);

    try {
      final workingDays = _workingDays.entries
          .where((e) => e.value)
          .map((e) => e.key.toLowerCase())
          .toList();

      final businessHours = {
        'open': '${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')}',
        'close': '${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}',
        'working_days': workingDays,
      };

      final result = await _vendorService.updateBusinessHours(businessHours);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working hours updated successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update working hours'),
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Working Hours'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveWorkingHours,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _isSaving
                      ? AppTheme.white.withValues(alpha: 0.5)
                      : AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Hours
                  Text(
                    'Business Hours',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectOpenTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.mediumGray),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('Open Time'),
                                const SizedBox(height: 8),
                                Text(
                                  _openTime.format(context),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectCloseTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.mediumGray),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('Close Time'),
                                const SizedBox(height: 8),
                                Text(
                                  _closeTime.format(context),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Working Days
                  Text(
                    'Working Days',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._workingDays.entries.map((entry) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: SwitchListTile(
                          title: Text(entry.key),
                          value: entry.value,
                          onChanged: (value) {
                            setState(() => _workingDays[entry.key] = value);
                          },
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}

