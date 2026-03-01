import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../widgets/screen_with_nav.dart';
import '../home/widgets/app_drawer.dart';
import '../../utils/logger.dart';

/// Product Catalog Screen - Display all products with pricing
class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _supabase = SupabaseConfig.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  
  // Dummy data flag - set to false when ready for production
  static const bool _useDummyData = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      // Get vendor ID
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      // Fetch vendor products with product details
      final response = await _supabase.from('vendor_products').select('''
            *,
            products!inner(id, name)
          ''').eq('vendor_id', vendorId).order('created_at', ascending: false);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });

      AppLogger.i('Loaded ${_products.length} products for catalog');
    } catch (e) {
      AppLogger.e('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNav(
      title: 'Product Catalog',
      drawer: const AppDrawer(),
      currentNavIndex: 3,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: _buildProductList(),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: AppTheme.lightGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Products Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add products in Inventory to see them here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final productInfo = product['products'] as Map<String, dynamic>;
        final productName = productInfo['name'] ?? 'Product';
        final sellingPrice = (product['selling_price'] as num?)?.toDouble() ?? 0.0;
        final depositAmount = (product['deposit_amount'] as num?)?.toDouble() ?? 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.mediumGray),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  productName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                // Selling Price
                Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Selling Price: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    Text(
                      'Rs. ${sellingPrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.successGreen,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Deposit Amount
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Deposit Amount: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    Text(
                      depositAmount > 0
                          ? 'Rs. ${depositAmount.toStringAsFixed(0)}'
                          : 'No deposit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: depositAmount > 0
                                ? AppTheme.warningOrange
                                : AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

