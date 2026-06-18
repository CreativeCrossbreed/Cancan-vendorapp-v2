import '../config/supabase_config.dart';

/// Stock Service - Handles stock reservation and management
class StockService {
  final _supabase = SupabaseConfig.client;

  /// Check available stock for a product
  /// Returns current_stock - reserved_stock
  Future<int> getAvailableStock({
    required String vendorId,
    required String productId,
  }) async {
    try {
      final response = await _supabase.rpc('get_available_stock', params: {
        'p_vendor_id': vendorId,
        'p_product_id': productId,
      });

      return response as int? ?? 0;
    } catch (e) {
      print('❌ Error getting available stock: $e');
      return 0;
    }
  }

  /// Reserve stock for an order
  /// Returns true if stock was successfully reserved
  Future<Map<String, dynamic>> reserveStockForOrder({
    required String orderId,
  }) async {
    try {
      final result = await _supabase.rpc('reserve_stock_for_order', params: {
        'p_order_id': orderId,
      });

      final success = result as bool? ?? false;

      if (success) {
        print('✅ Stock reserved for order: $orderId');
        return {'success': true, 'message': 'Stock reserved successfully'};
      } else {
        print('⚠️ Insufficient stock for order: $orderId');
        return {
          'success': false,
          'message': 'Insufficient stock available'
        };
      }
    } catch (e) {
      print('❌ Error reserving stock: $e');
      return {
        'success': false,
        'message': 'Failed to reserve stock: $e'
      };
    }
  }

  /// Release reserved stock when order is cancelled
  Future<Map<String, dynamic>> releaseReservedStock({
    required String orderId,
  }) async {
    try {
      await _supabase.rpc('release_reserved_stock', params: {
        'p_order_id': orderId,
      });

      print('✅ Reserved stock released for order: $orderId');
      return {'success': true, 'message': 'Stock released successfully'};
    } catch (e) {
      print('❌ Error releasing stock: $e');
      return {
        'success': false,
        'message': 'Failed to release stock: $e'
      };
    }
  }

  /// Convert reserved stock to actual delivery
  /// Called when order is marked as delivered
  Future<Map<String, dynamic>> convertReservedToDelivered({
    required String orderId,
  }) async {
    try {
      await _supabase.rpc('convert_reserved_to_delivered', params: {
        'p_order_id': orderId,
      });

      print('✅ Reserved stock converted to delivery for order: $orderId');
      return {'success': true, 'message': 'Stock updated successfully'};
    } catch (e) {
      print('❌ Error converting stock: $e');
      return {
        'success': false,
        'message': 'Failed to update stock: $e'
      };
    }
  }

  /// Check if stock is low and needs alert
  /// Returns true if vendor should be alerted
  Future<Map<String, dynamic>> checkLowStockAndAlert({
    required String vendorId,
    required String productId,
  }) async {
    try {
      final shouldAlert = await _supabase.rpc('check_low_stock_and_alert', params: {
        'p_vendor_id': vendorId,
        'p_product_id': productId,
      });

      final alertNeeded = shouldAlert as bool? ?? false;

      if (alertNeeded) {
        print('🚨 Low stock alert needed for product: $productId');
        return {
          'success': true,
          'alert_needed': true,
          'message': 'Stock is low. Please update inventory.'
        };
      } else {
        return {
          'success': true,
          'alert_needed': false,
          'message': 'Stock is sufficient'
        };
      }
    } catch (e) {
      print('❌ Error checking low stock: $e');
      return {
        'success': false,
        'alert_needed': false,
        'message': 'Failed to check stock level'
      };
    }
  }

  /// Get vendor products with stock information
  Future<List<Map<String, dynamic>>> getVendorProductsWithStock({
    required String vendorId,
  }) async {
    try {
      final response = await _supabase
          .from('vendor_products')
          .select('''
            *,
            products(id, name)
          ''')
          .eq('vendor_id', vendorId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('❌ Error fetching vendor products: $e');
      return [];
    }
  }

  /// Update stock quantity
  Future<Map<String, dynamic>> updateStock({
    required String vendorProductId,
    required int newStock,
  }) async {
    try {
      await _supabase.from('vendor_products').update({
        'current_stock': newStock,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', vendorProductId);

      print('✅ Stock updated to: $newStock');
      return {'success': true, 'message': 'Stock updated successfully'};
    } catch (e) {
      print('❌ Error updating stock: $e');
      return {
        'success': false,
        'message': 'Failed to update stock: $e'
      };
    }
  }

  /// Add stock to existing inventory
  Future<Map<String, dynamic>> addStock({
    required String vendorProductId,
    required int quantityToAdd,
  }) async {
    try {
      final response = await _supabase
          .from('vendor_products')
          .select('current_stock')
          .eq('id', vendorProductId)
          .single();

      final currentStock = response['current_stock'] as int? ?? 0;
      final newStock = currentStock + quantityToAdd;

      return updateStock(
        vendorProductId: vendorProductId,
        newStock: newStock,
      );
    } catch (e) {
      print('❌ Error adding stock: $e');
      return {
        'success': false,
        'message': 'Failed to add stock: $e'
      };
    }
  }
}
