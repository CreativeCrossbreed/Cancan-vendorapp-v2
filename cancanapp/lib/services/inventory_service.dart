import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Inventory Service - Handles inventory management operations
class InventoryService {
  final _supabase = SupabaseConfig.client;

  /// Get all products for the current vendor
  Future<List<Map<String, dynamic>>> getVendorProducts() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final response = await _supabase
          .from('vendor_products')
          .select('''
            *,
            products!inner(id, name, category)
          ''')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching vendor products: $e', e, stackTrace);
      return [];
    }
  }

  /// Update stock level
  Future<Map<String, dynamic>> updateStockLevel({
    required String vendorProductId,
    required int newStockLevel,
    String? reason,
  }) async {
    try {
      final updates = <String, dynamic>{
        'current_stock': newStockLevel,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (reason != null) {
        updates['last_stock_update_reason'] = reason;
      }

      // Check if stock is below threshold
      final product = await _supabase
          .from('vendor_products')
          .select('low_stock_threshold')
          .eq('id', vendorProductId)
          .single();

      final threshold = product['low_stock_threshold'] as int? ?? 10;
      if (newStockLevel <= threshold) {
        updates['is_low_stock'] = true;
        updates['low_stock_alert_sent_at'] = DateTime.now().toIso8601String();
      } else {
        updates['is_low_stock'] = false;
      }

      await _supabase
          .from('vendor_products')
          .update(updates)
          .eq('id', vendorProductId);

      // Create stock movement record
      await _recordStockMovement(
        vendorProductId: vendorProductId,
        quantity: newStockLevel,
        type: 'manual_update',
        reason: reason ?? 'Manual stock update',
      );

      return {
        'success': true,
        'message': 'Stock updated successfully',
      };
    } catch (e) {
      AppLogger.e('Error updating stock level: $e');
      return {
        'success': false,
        'message': 'Failed to update stock level',
      };
    }
  }

  /// Add new vendor product
  Future<Map<String, dynamic>> addVendorProduct({
    required String productId,
    required double sellingPrice,
    required double depositAmount,
    required int initialStock,
    required int lowStockThreshold,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final newProduct = {
        'vendor_id': vendorId,
        'product_id': productId,
        'selling_price': sellingPrice,
        'deposit_amount': depositAmount,
        'current_stock': initialStock,
        'low_stock_threshold': lowStockThreshold,
        'is_low_stock': initialStock <= lowStockThreshold,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('vendor_products')
          .insert(newProduct)
          .select('id')
          .single();

      // Create initial stock movement record
      await _recordStockMovement(
        vendorProductId: response['id'],
        quantity: initialStock,
        type: 'initial_stock',
        reason: 'Initial inventory setup',
      );

      return {
        'success': true,
        'message': 'Product added successfully',
        'product': newProduct,
      };
    } catch (e) {
      AppLogger.e('Error adding vendor product: $e');
      return {
        'success': false,
        'message': 'Failed to add product',
      };
    }
  }

  /// Get products with low stock
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final response = await _supabase
          .from('vendor_products')
          .select('''
            *,
            products!inner(id, name, category)
          ''')
          .eq('vendor_id', vendorId)
          .eq('is_low_stock', true)
          .order('current_stock', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching low stock products: $e', e, stackTrace);
      return [];
    }
  }

  /// Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStatistics() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final products = await _supabase
          .from('vendor_products')
          .select('current_stock, low_stock_threshold, is_low_stock')
          .eq('vendor_id', vendorId);

      int totalProducts = products.length;
      int lowStockProducts = 0;
      int totalStock = 0;
      double totalValue = 0.0;

      for (final product in products) {
        totalStock += product['current_stock'] as int;
        if (product['is_low_stock'] as bool) {
          lowStockProducts++;
        }
      }

      // Get product values
      final productsWithValue = await _supabase
          .from('vendor_products')
          .select('current_stock, selling_price')
          .eq('vendor_id', vendorId);

      for (final product in productsWithValue) {
        final stock = product['current_stock'] as int;
        final price = (product['selling_price'] as num).toDouble();
        totalValue += stock * price;
      }

      return {
        'totalProducts': totalProducts,
        'lowStockProducts': lowStockProducts,
        'totalStock': totalStock,
        'totalValue': totalValue,
        'lowStockPercentage': totalProducts > 0
            ? (lowStockProducts / totalProducts) * 100
            : 0.0,
      };
    } catch (e) {
      AppLogger.e('Error fetching inventory statistics: $e');
      return {
        'totalProducts': 0,
        'lowStockProducts': 0,
        'totalStock': 0,
        'totalValue': 0.0,
        'lowStockPercentage': 0.0,
      };
    }
  }

  /// Get stock movements for a product
  Future<List<Map<String, dynamic>>> getStockMovements(String vendorProductId) async {
    try {
      final response = await _supabase
          .from('stock_movements')
          .select('*')
          .eq('vendor_product_id', vendorProductId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching stock movements: $e', e, stackTrace);
      return [];
    }
  }

  /// Record stock movement
  Future<void> _recordStockMovement({
    required String vendorProductId,
    required int quantity,
    required String type,
    required String reason,
  }) async {
    try {
      await _supabase.from('stock_movements').insert({
        'vendor_product_id': vendorProductId,
        'quantity': quantity,
        'type': type,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.e('Error recording stock movement: $e');
    }
  }

  /// Update product details
  Future<Map<String, dynamic>> updateProduct({
    required String vendorProductId,
    double? sellingPrice,
    double? depositAmount,
    int? lowStockThreshold,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (sellingPrice != null) updates['selling_price'] = sellingPrice;
      if (depositAmount != null) updates['deposit_amount'] = depositAmount;
      if (lowStockThreshold != null) {
        updates['low_stock_threshold'] = lowStockThreshold;

        // Check if current stock is below new threshold
        final product = await _supabase
            .from('vendor_products')
            .select('current_stock')
            .eq('id', vendorProductId)
            .single();

        final currentStock = product['current_stock'] as int;
        updates['is_low_stock'] = currentStock <= lowStockThreshold;
      }

      await _supabase
          .from('vendor_products')
          .update(updates)
          .eq('id', vendorProductId);

      return {
        'success': true,
        'message': 'Product updated successfully',
      };
    } catch (e) {
      AppLogger.e('Error updating product: $e');
      return {
        'success': false,
        'message': 'Failed to update product',
      };
    }
  }

  /// Delete vendor product
  Future<Map<String, dynamic>> deleteVendorProduct(String vendorProductId) async {
    try {
      await _supabase
          .from('vendor_products')
          .delete()
          .eq('id', vendorProductId);

      return {
        'success': true,
        'message': 'Product deleted successfully',
      };
    } catch (e) {
      AppLogger.e('Error deleting vendor product: $e');
      return {
        'success': false,
        'message': 'Failed to delete product',
      };
    }
  }

  /// Get available products to add (from master products table)
  Future<List<Map<String, dynamic>>> getAvailableProducts() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      // Get products not already added by vendor
      final response = await _supabase
          .from('products')
          .select('*')
          .order('name');

      // Filter out products already added by this vendor
      final vendorProducts = await _supabase
          .from('vendor_products')
          .select('product_id')
          .eq('vendor_id', vendorId);

      final existingProductIds =
          (vendorProducts as List).map((p) => p['product_id'] as String).toSet();

      final availableProducts = (response as List)
          .where((p) => !existingProductIds.contains(p['id']))
          .toList();

      return List<Map<String, dynamic>>.from(availableProducts);
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching available products: $e', e, stackTrace);
      return [];
    }
  }
}