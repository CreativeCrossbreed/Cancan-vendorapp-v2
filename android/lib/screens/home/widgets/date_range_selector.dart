import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

enum DateRangeType {
  today,
  week,
  month,
  custom,
}

/// Date Range Selector - Date range picker component
class DateRangeSelector extends StatefulWidget {
  final DateRangeType initialRangeType;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateRangeType, DateTime?, DateTime?) onRangeChanged;
  final bool showQuickOptions;

  const DateRangeSelector({
    super.key,
    this.initialRangeType = DateRangeType.week,
    this.initialStartDate,
    this.initialEndDate,
    required this.onRangeChanged,
    this.showQuickOptions = true,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateRangeType _selectedRangeType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedRangeType = widget.initialRangeType;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;

    // Initialize default dates if not provided
    _initializeDates();
  }

  void _initializeDates() {
    final now = DateTime.now();

    if (_startDate == null || _endDate == null) {
      switch (_selectedRangeType) {
        case DateRangeType.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate!.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
          break;
        case DateRangeType.week:
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case DateRangeType.month:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
          break;
        case DateRangeType.custom:
          _startDate ??= now.subtract(const Duration(days: 7));
          _endDate ??= now;
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
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
            'Date Range',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.showQuickOptions) ...[
            _buildQuickOptions(),
            const SizedBox(height: 12),
          ],
          _buildSelectedRangeDisplay(),
        ],
      ),
    );
  }

  Widget _buildQuickOptions() {
    return Row(
      children: [
        _buildQuickOption(
          label: 'Today',
          isSelected: _selectedRangeType == DateRangeType.today,
          onTap: () => _selectRangeType(DateRangeType.today),
        ),
        const SizedBox(width: 8),
        _buildQuickOption(
          label: '7 Days',
          isSelected: _selectedRangeType == DateRangeType.week,
          onTap: () => _selectRangeType(DateRangeType.week),
        ),
        const SizedBox(width: 8),
        _buildQuickOption(
          label: 'This Month',
          isSelected: _selectedRangeType == DateRangeType.month,
          onTap: () => _selectRangeType(DateRangeType.month),
        ),
        const SizedBox(width: 8),
        _buildQuickOption(
          label: 'Custom',
          isSelected: _selectedRangeType == DateRangeType.custom,
          onTap: () => _selectRangeType(DateRangeType.custom),
        ),
      ],
    );
  }

  Widget _buildQuickOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedRangeDisplay() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final startText = _startDate != null ? dateFormat.format(_startDate!) : 'Select start';
    final endText = _endDate != null ? dateFormat.format(_endDate!) : 'Select end';

    return GestureDetector(
      onTap: _selectedRangeType == DateRangeType.custom ? _showCustomDatePicker : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _selectedRangeType == DateRangeType.custom
                ? AppTheme.primaryBlue.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: _selectedRangeType == DateRangeType.custom
                  ? AppTheme.primaryBlue
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    startText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _selectedRangeType == DateRangeType.custom
                          ? AppTheme.primaryBlue
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'to',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        endText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _selectedRangeType == DateRangeType.custom
                              ? AppTheme.primaryBlue
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_selectedRangeType == DateRangeType.custom)
              const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }

  void _selectRangeType(DateRangeType rangeType) {
    setState(() {
      _selectedRangeType = rangeType;
      _initializeDates();
    });

    widget.onRangeChanged(_selectedRangeType, _startDate, _endDate);
  }

  Future<void> _showCustomDatePicker() async {
    final startDate = await _showDatePicker(
      context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Start Date',
    );

    if (startDate != null && mounted) {
      final endDate = await _showDatePicker(
        context,
        initialDate: _endDate ?? DateTime.now(),
        firstDate: startDate,
        lastDate: DateTime.now(),
        helpText: 'Select End Date',
      );

      if (endDate != null && mounted) {
        setState(() {
          _startDate = startDate;
          _endDate = endDate;
        });

        widget.onRangeChanged(_selectedRangeType, _startDate, _endDate);
      }
    }
  }

  Future<DateTime?> _showDatePicker(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required String helpText,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryBlue,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}