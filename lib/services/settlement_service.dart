import '../config/supabase_config.dart';

/// Settlement service for platform-collected payment payouts.
class SettlementService {
  final _supabase = SupabaseConfig.client;

  Future<Map<String, dynamic>> getVendorSettlementSummary() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'availableBalance': 0.0,
          'totalPaidOut': 0.0,
          'pendingPayouts': 0,
        };
      }

      final ledgerRows = await _supabase
          .from('vendor_wallet_ledger')
          .select('entry_type, amount, status')
          .eq('vendor_id', vendorId)
          .eq('status', 'posted');

      double availableBalance = 0.0;
      for (final row in ledgerRows) {
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final type = row['entry_type'] as String? ?? 'credit';
        if (type == 'debit' || type == 'reversal') {
          availableBalance -= amount;
        } else {
          availableBalance += amount;
        }
      }

      final payoutRows = await _supabase
          .from('payout_items')
          .select('amount, status')
          .eq('vendor_id', vendorId);

      double totalPaidOut = 0.0;
      int pendingPayouts = 0;
      for (final row in payoutRows) {
        final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
        final status = row['status'] as String? ?? '';
        if (status == 'paid') totalPaidOut += amount;
        if (status == 'scheduled' || status == 'processing') pendingPayouts += 1;
      }

      return {
        'availableBalance': availableBalance < 0 ? 0.0 : availableBalance,
        'totalPaidOut': totalPaidOut,
        'pendingPayouts': pendingPayouts,
      };
    } catch (e) {
      // Keep screen resilient when settlement tables are not yet migrated.
      return {
        'availableBalance': 0.0,
        'totalPaidOut': 0.0,
        'pendingPayouts': 0,
      };
    }
  }
}
