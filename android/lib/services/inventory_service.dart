import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Inventory Service - Handles product inventory operations with Supabase
class InventoryService {
  final _supabase = SupabaseConfig.client;

  /// Get vendor's products with inventory
  Future<List<Map<String, dynamic>>> getVendorProducts() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return [];
      }

      AppLogger.d('Fetching vendor products for: $vendorId');

      final response = await _supabase
          .from('vendor_products')
          .select('''
            id,
            vendor_id,
            product_id,
            products!inner(
              id,
              name,
              category,
              base_price,
              image_url
            ),
            selling_price,
            deposit_amount,
            mrp,
            current_stock,
            low_stock_threshold,
            reorder_quantity,
            is_active,
            is_available
          ''')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      AppLogger.i('Fetched ${response.length} products');

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      AppLogger.e('Error fetching products: $e');
      return [];
    }
  }

  /// Get low stock items
  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return [];
      }

      AppLogger.d('Fetching low stock items for vendor: $vendorId');

      final response = await _supabase
          .from('vendor_products')
          .select('''
            id,
            product_id,
            products!inner(
              id,
              name
            ),
            current_stock,
            low_stock_threshold
          ''')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .lt('current_stock', 'low_stock_threshold')
          .order('current_stock', ascending: true);

      AppLogger.i('Fetched ${response.length} low stock items');

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      AppLogger.e('Error fetching low stock items: $e');
      return [];
    }
  }

  /// Update product stock
  Future<Map<String, dynamic>> updateStock({
    required String vendorProductId,
    required int quantityChange,
    String? notes,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Updating stock for product: $vendorProductId, change: $quantityChange');

      // Get current product
      final productResponse = await _supabase
          .from('vendor_products')
          .select('current_stock')
          .eq('id', vendorProductId)
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (productResponse == null) {
        return {
          'success': false,
          'message': 'Product not found',
        };
      }

      final currentStock = productResponse['current_stock'] as int;
      final newStock = currentStock + quantityChange;

      if (newStock < 0) {
        return {
          'success': false,
          'message': 'Insufficient stock',
        };
      }

      final error = await _supabase
          .from('vendor_products')
          .update({
            'current_stock': newStock,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorProductId)
          .eq('vendor_id', vendorId);

      if (error != null) {
        AppLogger.e('Error updating stock: $error');
        return {
          'success': false,
          'message': 'Failed to update stock',
          'error': error.toString(),
        };
      }

      // Log inventory transaction
      await _supabase.from('inventory_transactions').insert({
        'vendor_id': vendorId,
        'product_id': (await _supabase
                .from('vendor_products')
                .select('product_id')
                .eq('id', vendorProductId)
                .maybeSingle())?['product_id'],
        'transaction_type': quantityChange > 0 ? 'stock_in' : 'stock_out',
        'quantity': quantityChange.abs(),
        'remaining_stock': newStock,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.i('Stock updated successfully');
      return {
        'success': true,
        'message': 'Stock updated successfully',
        'newStock': newStock,
      };
    } catch (e) {
      AppLogger.e('Error updating stock: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Add new product to vendor's catalog
  Future<Map<String, dynamic>> addProduct({
    required String productId,
    required double sellingPrice,
    required int initialStock,
    int? lowStockThreshold,
    int? reorderQuantity,
    double? depositAmount,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Adding product to vendor catalog: $vendorId, product: $productId');

      final productData = {
        'vendor_id': vendorId,
        'product_id': productId,
        'selling_price': sellingPrice,
        'deposit_amount': depositAmount ?? 0.0,
        'current_stock': initialStock,
        'low_stock_threshold': lowStockThreshold ?? 10,
        'reorder_quantity': reorderQuantity ?? 50,
        'is_active': true,
        'is_available': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final error = await _supabase
          .from('vendor_products')
          .insert(productData);

      if (error != null) {
        AppLogger.e('Error adding product: $error');
        return {
          'success': false,
          'message': 'Failed to add product',
          'error': error.toString(),
        };
      }

      // Log inventory transaction
      await _supabase.from('inventory_transactions').insert({
        'vendor_id': vendorId,
        'product_id': productId,
        'transaction_type': 'stock_in',
        'quantity': initialStock,
        'remaining_stock': initialStock,
        'notes': 'Initial stock',
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.i('Product added successfully');
      return {
        'success': true,
        'message': 'Product added successfully',
      };
    } catch (e) {
      AppLogger.e('Error adding product: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Update product details
  Future<Map<String, dynamic>> updateProduct({
    required String vendorProductId,
    double? sellingPrice,
    double? depositAmount,
    int? lowStockThreshold,
    int? reorderQuantity,
    bool? isAvailable,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'success': false,
          'message': 'No vendor ID found',
        };
      }

      AppLogger.d('Updating product: $vendorProductId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (sellingPrice != null) updateData['selling_price'] = sellingPrice;
      if (depositAmount != null) updateData['deposit_amount'] = depositAmount;
      if (lowStockThreshold != null) updateData['low_stock_threshold'] = lowStockThreshold;
      if (reorderQuantity != null) updateData['reorder_quantity'] = reorderQuantity;
      if (isAvailable != null) updateData['is_available'] = isAvailable;

      final error = await _supabase
          .from('vendor_products')
          .update(updateData)
          .eq('id', vendorProductId)
          .eq('vendor_id', vendorId);

      if (error != null) {
        AppLogger.e('Error updating product: $error');
        return {
          'success': false,
          'message': 'Failed to update product',
          'error': error.toString(),
        };
      }

      AppLogger.i('Product updated successfully');
      return {
        'success': true,
        'message': 'Product updated successfully',
      };
    } catch (e) {
      AppLogger.e('Error updating product: $e');
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        return {
          'totalProducts': 0,
          'lowStockCount': 0,
          'totalStock': 0,
          'outOfStockCount': 0,
        };
      }

      AppLogger.d('Fetching inventory stats for vendor: $vendorId');

      final response = await _supabase
          .from('vendor_products')
          .select('current_stock, low_stock_threshold')
          .eq('vendor_id', vendorId)
          .eq('is_active', true);

      final products = response as List;

      final totalProducts = products.length;
      final lowStockCount = products
          .where((p) => (p['current_stock'] as int) <= (p['low_stock_threshold'] as int))
          .length;
      final totalStock = products.fold<int>(
          0, (sum, p) => sum + (p['current_stock'] as int));
      final outOfStockCount = products
          .where((p) => (p['current_stock'] as int) == 0)
          .length;

      return {
        'totalProducts': totalProducts,
        'lowStockCount': lowStockCount,
        'totalStock': totalStock,
        'outOfStockCount': outOfStockCount,
      };
    } catch (e) {
      AppLogger.e('Error fetching inventory stats: $e');
      return {
        'totalProducts': 0,
        'lowStockCount': 0,
        'totalStock': 0,
        'outOfStockCount': 0,
      };
    }
  }

  /// Alias for getLowStockItems - for compatibility
  Future<List<Map<String, dynamic>>> getLowStockProducts() => getLowStockItems();

  /// Alias for getInventoryStats - for compatibility
  Future<Map<String, dynamic>> getInventoryStatistics() => getInventoryStats();
}
