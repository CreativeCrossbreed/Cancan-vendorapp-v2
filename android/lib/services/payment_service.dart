import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Payment Service - Handles payment operations with Supabase
class PaymentService {
  final _supabase = SupabaseConfig.client;

  /// Get payment history for current vendor
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    int? limit,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return [];
      }

      AppLogger.d('Fetching payment history for vendor: $vendorId');

      // Build query - select first, then filters
      var query = _supabase
          .from('payments')
          .select('''
            id,
            order_id,
            vendor_id,
            payment_method,
            amount,
            commission_amount,
            vendor_amount,
            status,
            created_at,
            processed_at,
            orders!inner(
              id,
              order_number,
              status
            )
          ''')
          .eq('vendor_id', vendorId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      List<dynamic> resultList = response;
      if (limit != null && resultList.length > limit) {
        resultList = resultList.sublist(0, limit);
      }

      AppLogger.i('Fetched ${resultList.length} payments');

      return resultList.cast<Map<String, dynamic>>();
    } catch (e) {
      AppLogger.e('Error fetching payment history: $e');
      return [];
    }
  }

  /// Get wallet balance
  Future<Map<String, dynamic>?> getWalletBalance() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return null;
      }

      AppLogger.d('Fetching wallet balance for vendor: $vendorId');

      final response = await _supabase
          .from('vendor_wallets')
          .select('balance, pending_balance')
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final balance = (response['balance'] as num?)?.toDouble() ?? 0.0;
      final pendingBalance = (response['pending_balance'] as num?)?.toDouble() ?? 0.0;

      return {
        'balance': balance,
        'pending_balance': pendingBalance,
        'total': balance + pendingBalance,
      };
    } catch (e) {
      AppLogger.e('Error fetching wallet balance: $e');
      return null;
    }
  }

  /// Get wallet transaction history
  Future<List<Map<String, dynamic>>> getWalletTransactions({
    int? limit,
    String? type,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return [];
      }

      AppLogger.d('Fetching wallet transactions for vendor: $vendorId');

      // Build query - select first, then filters
      var query = _supabase
          .from('wallet_transactions')
          .select('''
            id,
            vendor_id,
            transaction_type,
            amount,
            balance_after,
            description,
            reference_id,
            reference_type,
            status,
            created_at,
            processed_at
          ''')
          .eq('vendor_id', vendorId);

      if (type != null) {
        query = query.eq('transaction_type', type);
      }

      final response = await query.order('created_at', ascending: false);

      List<dynamic> resultList = response;
      if (limit != null && resultList.length > limit) {
        resultList = resultList.sublist(0, limit);
      }

      AppLogger.i('Fetched ${resultList.length} wallet transactions');

      return resultList.cast<Map<String, dynamic>>();
    } catch (e) {
      AppLogger.e('Error fetching wallet transactions: $e');
      return [];
    }
  }

  /// Request payout
  Future<Map<String, dynamic>> requestPayout(double amount) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Requesting payout for vendor: $vendorId, amount: $amount');

      // Get current wallet balance
      final walletResponse = await _supabase
          .from('vendor_wallets')
          .select('balance')
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (walletResponse == null) {
        return {
          'success': false,
          'message': 'Wallet not found',
        };
      }

      final currentBalance = (walletResponse['balance'] as num?)?.toDouble() ?? 0.0;

      if (currentBalance < amount) {
        return {
          'success': false,
          'message': 'Insufficient balance',
        };
      }

      // Create payout transaction
      final transactionData = {
        'vendor_id': vendorId,
        'transaction_type': 'debit',
        'amount': amount,
        'description': 'Payout request',
        'reference_type': 'payout',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final error = await _supabase
          .from('wallet_transactions')
          .insert(transactionData);

      if (error != null) {
        AppLogger.e('Error creating payout request: $error');
        return {
          'success': false,
          'message': 'Failed to request payout',
          'error': error.toString(),
        };
      }

      AppLogger.i('Payout requested successfully');
      return {
        'success': true,
        'message': 'Payout request submitted',
      };
    } catch (e) {
      AppLogger.e('Error requesting payout: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Get payment by order ID
  Future<Map<String, dynamic>?> getPaymentByOrderId(String orderId) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return null;
      }

      AppLogger.d('Fetching payment for order: $orderId');

      final response = await _supabase
          .from('payments')
          .select()
          .eq('order_id', orderId)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('Error fetching payment: $e');
      return null;
    }
  }
}
