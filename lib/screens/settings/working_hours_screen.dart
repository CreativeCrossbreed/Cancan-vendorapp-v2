import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/vendor_data_service.dart';
import '../../config/supabase_config.dart';
import '../home/widgets/app_drawer.dart';

class _DayHours {
  bool isOpen;
  TimeOfDay openTime;
  TimeOfDay closeTime;

  _DayHours({
    this.isOpen = true,
    this.openTime = const TimeOfDay(hour: 9, minute: 0),
    this.closeTime = const TimeOfDay(hour: 18, minute: 0),
  });
}

/// Working Hours Screen — per-day open/close times (a vendor open shorter
/// hours on Sundays, say, isn't forced into one shared time for every day).
///
/// Pass [isOnboarding] + [onComplete] to use this as a step right after
/// profile setup during signup, instead of only reachable later via Settings.
class WorkingHoursScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onComplete;

  const WorkingHoursScreen({super.key, this.isOnboarding = false, this.onComplete});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  static const List<String> _dayKeys = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];
  static const Map<String, String> _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  final Map<String, _DayHours> _days = {
    for (final key in _dayKeys) key: _DayHours(isOpen: key != 'sunday'),
  };

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  TimeOfDay _parseTime(String value, TimeOfDay fallback) {
    final parts = value.split(':');
    if (parts.length < 2) return fallback;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? fallback.hour, minute: int.tryParse(parts[1]) ?? fallback.minute);
  }

  Future<void> _loadWorkingHours() async {
    setState(() => _isLoading = true);
    try {
      final data = widget.isOnboarding ? null : await VendorDataService.getVendorProfile();
      final workingHours = data?['working_hours'] as Map<String, dynamic>?;

      if (workingHours != null) {
        // Per-day format: { "monday": { "is_open": true, "open": "09:00", "close": "18:00" }, ... }
        // Falls back gracefully if an older single-shared-time row is read
        // (legacy shape: { "open": "09:00", "close": "18:00" } + separate working_days list).
        final looksPerDay = _dayKeys.any((d) => workingHours[d] is Map);
        if (looksPerDay) {
          for (final key in _dayKeys) {
            final dayData = workingHours[key] as Map<String, dynamic>?;
            if (dayData == null) continue;
            final existing = _days[key]!;
            _days[key] = _DayHours(
              isOpen: dayData['is_open'] as bool? ?? existing.isOpen,
              openTime: _parseTime(dayData['open']?.toString() ?? '', existing.openTime),
              closeTime: _parseTime(dayData['close']?.toString() ?? '', existing.closeTime),
            );
          }
        } else {
          final sharedOpen = _parseTime(workingHours['open']?.toString() ?? '', const TimeOfDay(hour: 9, minute: 0));
          final sharedClose = _parseTime(workingHours['close']?.toString() ?? '', const TimeOfDay(hour: 18, minute: 0));
          final legacyDays = (data?['working_days'] as List?)?.map((d) => d.toString()).toSet() ?? {};
          for (final key in _dayKeys) {
            _days[key] = _DayHours(
              isOpen: legacyDays.isEmpty ? _days[key]!.isOpen : legacyDays.contains(key),
              openTime: sharedOpen,
              closeTime: sharedClose,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading working hours: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickTime(String dayKey, bool isOpenTime) async {
    final day = _days[dayKey]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpenTime ? day.openTime : day.closeTime,
    );
    if (picked == null) return;
    setState(() {
      if (isOpenTime) {
        day.openTime = picked;
      } else {
        day.closeTime = picked;
      }
    });
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<bool> _saveWorkingHours() async {
    setState(() => _isSaving = true);

    try {
      final workingHours = {
        for (final key in _dayKeys)
          key: {
            'is_open': _days[key]!.isOpen,
            'open': _fmt(_days[key]!.openTime),
            'close': _fmt(_days[key]!.closeTime),
          },
      };

      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('No vendor ID found');
      }

      await SupabaseConfig.client
          .from('vendors')
          .update({
            'working_hours': workingHours,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      await VendorDataService.clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ Error saving working hours: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onSavePressed() async {
    final success = await _saveWorkingHours();
    if (!mounted || !success) return;

    if (widget.isOnboarding) {
      widget.onComplete?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Working hours updated successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isOnboarding) ...[
                  Text(
                    'Set your working hours',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can change this anytime from Settings.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                ],
                ..._dayKeys.map((key) => _buildDayRow(key)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onSavePressed,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.white),
                          )
                        : Text(widget.isOnboarding ? 'Continue' : 'Save'),
                  ),
                ),
                if (widget.isOnboarding) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isSaving ? null : widget.onComplete,
                      child: const Text('Skip for now'),
                    ),
                  ),
                ],
              ],
            ),
          );

    if (widget.isOnboarding) {
      return Scaffold(body: SafeArea(child: body));
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Working Hours'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildDayRow(String dayKey) {
    final day = _days[dayKey]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.mediumGray),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_dayLabels[dayKey]!, style: const TextStyle(fontWeight: FontWeight.w600)),
              Switch(
                value: day.isOpen,
                onChanged: (v) => setState(() => day.isOpen = v),
              ),
            ],
          ),
          if (day.isOpen)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(dayKey, true),
                    child: Text(day.openTime.format(context)),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to')),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(dayKey, false),
                    child: Text(day.closeTime.format(context)),
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Closed', style: TextStyle(color: AppTheme.textSecondary)),
            ),
        ],
      ),
    );
  }
}
