import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Inventory Service - Handles inventory operations
class InventoryService {
  final _supabase = SupabaseConfig.client;

  /// Deduct stock from inventory when order is delivered
  /// Returns success status and message
  Future<Map<String, dynamic>> deductStockForOrder({
    required String orderId,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'Vendor not authenticated',
        };
      }

      // Get order items with product IDs
      final orderItems = await _supabase
          .from('order_items')
          .select('product_id, quantity')
          .eq('order_id', orderId);

      if (orderItems.isEmpty) {
        return {
          'success': false,
          'message': 'No items found in order',
        };
      }

      // Deduct stock for each product
      for (final item in orderItems) {
        final productId = item['product_id'] as String;
        final quantity = item['quantity'] as int;

        // Find vendor_product by vendor_id and product_id
        final vendorProducts = await _supabase
            .from('vendor_products')
            .select('id, current_stock')
            .eq('vendor_id', vendorId)
            .eq('product_id', productId)
            .limit(1)
            .maybeSingle();

        if (vendorProducts != null) {
          final currentStock = vendorProducts['current_stock'] as int;
          final newStock =
              (currentStock - quantity).clamp(0, double.infinity).toInt();

          await _supabase.from('vendor_products').update(
              {'current_stock': newStock}).eq('id', vendorProducts['id']);

          AppLogger.d(
              '✅ Deducted $quantity from product $productId. New stock: $newStock');
        } else {
          AppLogger.d('⚠️ Vendor product not found for product_id: $productId');
        }
      }

      return {
        'success': true,
        'message': 'Stock deducted successfully',
      };
    } catch (e) {
      AppLogger.d('❌ Error deducting stock: $e');
      return {
        'success': false,
        'message': 'Failed to deduct stock: $e',
      };
    }
  }

  /// Get all vendor products (for matching with orders)
  Future<List<Map<String, dynamic>>> getVendorProducts() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) return [];

      final response = await _supabase.from('vendor_products').select('''
            *,
            products!inner(id, name)
          ''').eq('vendor_id', vendorId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      AppLogger.d('❌ Error fetching vendor products: $e');
      return [];
    }
  }

  /// Get low stock vendor products
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) return [];

      final response = await _supabase
          .from('vendor_products')
          .select('''
            *,
            products!inner(id, name)
          ''')
          .eq('vendor_id', vendorId)
          .lte('current_stock', 10); // default threshold
      // Ideally should use low_stock_threshold column if it exists

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      AppLogger.d('❌ Error fetching low stock products: $e');
      return [];
    }
  }

  /// Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStatistics() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) return {'totalProducts': 0, 'lowStockCount': 0};

      final products = await getVendorProducts();
      final lowStock = await getLowStockProducts();

      return {
        'totalProducts': products.length,
        'lowStockCount': lowStock.length,
      };
    } catch (e) {
      AppLogger.d('❌ Error computing stats: $e');
      return {'totalProducts': 0, 'lowStockCount': 0};
    }
  }
}
