import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Payment Service - Handles payment processing and wallet management
class PaymentService {
  final _supabase = SupabaseConfig.client;

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      var query = _supabase
          .from('payments')
          .select('''
            *,
            orders!inner(id, total_amount, created_at)
          ''')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      return List<Map<String, dynamic>>.from(await query);
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching payment history: $e', e, stackTrace);
      return [];
    }
  }

  /// Get wallet balance
  Future<double> getWalletBalance() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final result = await _supabase
          .from('vendor_wallets')
          .select('balance')
          .eq('vendor_id', vendorId)
          .single();

      return (result['balance'] as num).toDouble();
    } catch (e) {
      AppLogger.e('Error fetching wallet balance: $e');
      return 0.0;
    }
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // Get total payments
      final allPayments = await _supabase
          .from('payments')
          .select('amount, status')
          .eq('vendor_id', vendorId);

      // Get this month's payments
      final monthlyPayments = await _supabase
          .from('payments')
          .select('amount, status')
          .eq('vendor_id', vendorId)
          .gte('created_at', monthStart.toIso8601String());

      double totalRevenue = 0.0;
      double monthlyRevenue = 0.0;
      int completedPayments = 0;
      int pendingPayments = 0;

      for (final payment in allPayments) {
        final amount = (payment['amount'] as num).toDouble();
        final status = payment['status'] as String;

        if (status == 'completed') {
          totalRevenue += amount;
          completedPayments++;
        } else if (status == 'pending') {
          pendingPayments++;
        }
      }

      for (final payment in monthlyPayments) {
        if (payment['status'] == 'completed') {
          monthlyRevenue += (payment['amount'] as num).toDouble();
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'monthlyRevenue': monthlyRevenue,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'walletBalance': await getWalletBalance(),
      };
    } catch (e) {
      AppLogger.e('Error fetching payment statistics: $e');
      return {
        'totalRevenue': 0.0,
        'monthlyRevenue': 0.0,
        'completedPayments': 0,
        'pendingPayments': 0,
        'walletBalance': 0.0,
      };
    }
  }

  /// Request withdrawal
  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String accountDetails,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final walletBalance = await getWalletBalance();
      if (amount > walletBalance) {
        return {
          'success': false,
          'message': 'Insufficient balance',
        };
      }

      await _supabase.from('withdrawal_requests').insert({
        'vendor_id': vendorId,
        'amount': amount,
        'account_details': accountDetails,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Withdrawal request submitted successfully',
      };
    } catch (e) {
      AppLogger.e('Error requesting withdrawal: $e');
      return {
        'success': false,
        'message': 'Failed to submit withdrawal request',
      };
    }
  }
}