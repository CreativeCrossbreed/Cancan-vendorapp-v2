import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/vendor_data_service.dart';
import '../../config/supabase_config.dart';
import '../../widgets/screen_with_nav.dart';
import '../home/widgets/app_drawer.dart';

/// Vacation Mode Screen - Enable/disable vacation mode with dates
class VacationModeScreen extends StatefulWidget {
  const VacationModeScreen({super.key});

  @override
  State<VacationModeScreen> createState() => _VacationModeScreenState();
}

class _VacationModeScreenState extends State<VacationModeScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOnVacation = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadVacationStatus();
  }

  Future<void> _loadVacationStatus() async {
    setState(() => _isLoading = true);

    try {
      // Use cached data - no API call if cache is valid
      final data = await VendorDataService.getVendorProfile();
      if (data != null) {
        setState(() {
          _isOnVacation = data['is_on_vacation'] ?? false;
          if (data['vacation_start_date'] != null) {
            _startDate = DateTime.parse(data['vacation_start_date']);
          }
          if (data['vacation_end_date'] != null) {
            _endDate = DateTime.parse(data['vacation_end_date']);
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading vacation status: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveVacationMode() async {
    if (_isOnVacation && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_isOnVacation && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('No vendor ID found');
      }

      // Update vacation mode in Supabase
      await SupabaseConfig.client
          .from('vendors')
          .update({
            'is_on_vacation': _isOnVacation,
            'vacation_start_date': _isOnVacation ? _startDate?.toIso8601String() : null,
            'vacation_end_date': _isOnVacation ? _endDate?.toIso8601String() : null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      // Clear cache to force refresh on next load
      await VendorDataService.clearCache();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isOnVacation ? 'Vacation mode enabled' : 'Vacation mode disabled'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      // Reload data to reflect changes
      await _loadVacationStatus();
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
    return ScreenWithNav(
      title: 'Vacation Mode',
      drawer: const AppDrawer(),
      currentNavIndex: 0,
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: _isSaving ? null : _saveVacationMode,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'When vacation mode is enabled, customers won\'t be able to place new orders during this period.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Vacation Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vacation Mode',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isOnVacation
                                ? 'Currently on vacation'
                                : 'Currently active',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isOnVacation,
                        onChanged: (value) {
                          setState(() => _isOnVacation = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  if (_isOnVacation) ...[
                    // Start Date
                    Text(
                      'Start Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectStartDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.mediumGray),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _startDate != null
                                  ? DateFormat('d MMM yyyy').format(_startDate!)
                                  : 'Select start date',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Icon(Icons.calendar_today, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // End Date
                    Text(
                      'End Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectEndDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.mediumGray),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _endDate != null
                                  ? DateFormat('d MMM yyyy').format(_endDate!)
                                  : 'Select end date',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Icon(Icons.calendar_today, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

