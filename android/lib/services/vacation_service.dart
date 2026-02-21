import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Vacation Service - Handles vacation mode settings and management
class VacationService {
  final _supabase = SupabaseConfig.client;

  /// Get current vacation status
  Future<Map<String, dynamic>> getVacationStatus() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final result = await _supabase
          .from('vendor_settings')
          .select('*')
          .eq('vendor_id', vendorId)
          .single();

      return {
        'isOnVacation': result['is_on_vacation'] ?? false,
        'vacationStartDate': result['vacation_start_date'],
        'vacationEndDate': result['vacation_end_date'],
        'vacationMessage': result['vacation_message'] ?? 'Currently on vacation',
        'autoReplyEnabled': result['auto_reply_enabled'] ?? false,
      };
    } catch (e) {
      AppLogger.e('Error fetching vacation status: $e');
      return {
        'isOnVacation': false,
        'vacationStartDate': null,
        'vacationEndDate': null,
        'vacationMessage': 'Currently on vacation',
        'autoReplyEnabled': false,
      };
    }
  }

  /// Enable vacation mode
  Future<Map<String, dynamic>> enableVacationMode({
    required DateTime startDate,
    required DateTime endDate,
    required String message,
    bool enableAutoReply = true,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final updates = {
        'is_on_vacation': true,
        'vacation_start_date': startDate.toIso8601String(),
        'vacation_end_date': endDate.toIso8601String(),
        'vacation_message': message,
        'auto_reply_enabled': enableAutoReply,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('vendor_settings')
          .upsert({
            'vendor_id': vendorId,
            ...updates,
          });

      return {
        'success': true,
        'message': 'Vacation mode enabled successfully',
      };
    } catch (e) {
      AppLogger.e('Error enabling vacation mode: $e');
      return {
        'success': false,
        'message': 'Failed to enable vacation mode',
      };
    }
  }

  /// Disable vacation mode
  Future<Map<String, dynamic>> disableVacationMode() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      await _supabase
          .from('vendor_settings')
          .update({
            'is_on_vacation': false,
            'vacation_start_date': null,
            'vacation_end_date': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('vendor_id', vendorId);

      return {
        'success': true,
        'message': 'Vacation mode disabled successfully',
      };
    } catch (e) {
      AppLogger.e('Error disabling vacation mode: $e');
      return {
        'success': false,
        'message': 'Failed to disable vacation mode',
      };
    }
  }

  /// Extend vacation period
  Future<Map<String, dynamic>> extendVacationPeriod({
    required DateTime newEndDate,
    String? updatedMessage,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final updates = <String, dynamic>{
        'vacation_end_date': newEndDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (updatedMessage != null) {
        updates['vacation_message'] = updatedMessage;
      }

      await _supabase
          .from('vendor_settings')
          .update(updates)
          .eq('vendor_id', vendorId);

      return {
        'success': true,
        'message': 'Vacation period extended successfully',
      };
    } catch (e) {
      AppLogger.e('Error extending vacation period: $e');
      return {
        'success': false,
        'message': 'Failed to extend vacation period',
      };
    }
  }

  /// Check if vacation mode should be automatically disabled
  Future<bool> checkAndUpdateVacationStatus() async {
    try {
      final status = await getVacationStatus();

      if (status['isOnVacation'] == true) {
        final endDate = status['vacationEndDate'] as String?;
        if (endDate != null) {
          final endDateTime = DateTime.parse(endDate);
          if (DateTime.now().isAfter(endDateTime)) {
            // Vacation period has ended, disable vacation mode
            await disableVacationMode();
            return false;
          }
        }
      }

      return status['isOnVacation'] as bool;
    } catch (e) {
      AppLogger.e('Error checking vacation status: $e');
      return false;
    }
  }

  /// Get vacation statistics
  Future<Map<String, dynamic>> getVacationStatistics() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      // This would require historical vacation tracking
      // For now, return current status as statistics
      final status = await getVacationStatus();

      return {
        'currentStatus': status,
        'totalVacationDays': 0, // Would require historical data
        'vacationDaysThisYear': 0, // Would require historical data
        'averageVacationDuration': 0, // Would require historical data
      };
    } catch (e) {
      AppLogger.e('Error fetching vacation statistics: $e');
      return {
        'currentStatus': {},
        'totalVacationDays': 0,
        'vacationDaysThisYear': 0,
        'averageVacationDuration': 0,
      };
    }
  }
}