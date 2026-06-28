import '../config/supabase_config.dart';

class VendorCustomer {
  final String id;
  final String name;
  final String phone;
  final String? floor;
  final bool? hasLift;
  final String address;
  final double depositAmount;

  VendorCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.floor,
    this.hasLift,
    this.depositAmount = 0.0,
  });

  factory VendorCustomer.fromJson(Map<String, dynamic> json) {
    return VendorCustomer(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      floor: json['floor'] as String?,
      hasLift: json['has_lift'] as bool?,
      // Reuses the existing `deposit_paid` column (refundable can deposit) —
      // there is no separate `deposit_amount` column on the real schema.
      depositAmount: (json['deposit_paid'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Customer Service — vendor-facing customer database (read + edit
/// delivery-relevant fields like floor/lift/deposit). Each customer belongs
/// to exactly one vendor via customers.vendor_id (direct ownership, not a
/// many-to-many join table) — RLS on `customers` already scopes this to
/// `vendor_id = auth.uid()`.
class CustomerService {
  final _supabase = SupabaseConfig.client;

  Future<List<VendorCustomer>> getCustomers({String? searchQuery}) async {
    final vendorId = SupabaseConfig.currentVendorId;
    if (vendorId == null) return [];

    try {
      final response = await _supabase
          .from('customers')
          .select('id, name, phone, address, floor, has_lift, deposit_paid')
          .eq('vendor_id', vendorId);

      var customers = (response as List)
          .map((c) => VendorCustomer.fromJson(c as Map<String, dynamic>))
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        customers = customers
            .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
            .toList();
      }

      customers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return customers;
    } catch (e) {
      print('❌ Error fetching customers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateCustomerDeliveryDetails({
    required String customerId,
    String? floor,
    bool? hasLift,
    double? depositAmount,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (floor != null) updates['floor'] = floor;
      if (hasLift != null) updates['has_lift'] = hasLift;
      if (depositAmount != null) updates['deposit_paid'] = depositAmount;

      if (updates.isEmpty) return {'success': true};

      await _supabase.from('customers').update(updates).eq('id', customerId);
      return {'success': true};
    } catch (e) {
      print('❌ Error updating customer: $e');
      return {'success': false, 'message': 'Failed to update customer'};
    }
  }
}
