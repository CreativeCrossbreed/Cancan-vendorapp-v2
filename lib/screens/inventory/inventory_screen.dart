import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../home/widgets/app_drawer.dart';

/// Inventory Screen - Manage stock levels
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _supabase = SupabaseConfig.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  
  // Dummy data flag - set to false when ready for production
  static const bool _useDummyData = false;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);

    try {
      if (_useDummyData) {
        // Use dummy data for testing
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        setState(() {
          _products = _generateDummyProducts();
          _isLoading = false;
        });
        print('✅ Loaded ${_products.length} dummy products');
        return;
      }

      // Get vendor ID
      final vendorId = SupabaseConfig.currentVendorId ??
          '5d4b8601-2bef-4ce3-8631-b62730d403ea';

      // Fetch vendor products with product details
      final response = await _supabase.from('vendor_products').select('''
            *,
            products!inner(id, name)
          ''').eq('vendor_id', vendorId).order('created_at', ascending: false);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });

      print('✅ Loaded ${_products.length} products');
    } catch (e) {
      print('❌ Error loading inventory: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _generateDummyProducts() {
    final vendorId = SupabaseConfig.currentVendorId ??
        '5d4b8601-2bef-4ce3-8631-b62730d403ea';

    return [
      {
        'id': 'dummy-vp-1',
        'vendor_id': vendorId,
        'product_id': 'dummy-product-1',
        'selling_price': 50.0,
        'deposit_amount': 0.0,
        'current_stock': 30,
        'low_stock_threshold': 10,
        'products': {
          'id': 'dummy-product-1',
          'name': 'Bisleri water cans',
        },
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: AppTheme.paddingXXL,
                child: Column(
                  children: [
                    // Hamburger + Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Isolated hamburger icon
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: AppTheme.white),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        // Center title/subtitle
                        Column(
                          children: [
                            Text(
                              'Inventory',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.white.withValues(alpha: 0.9),
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingXS),
                            Text(
                              'Track your Water Cans Stock',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        // Balance spacing
                        const SizedBox(width: 48),
                      ],
                    ),
                  ],
                ),
              ),
              // Body content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadInventory,
                            child: _buildInventoryList(),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add_rounded, color: AppTheme.primaryBlue),
        label: const Text('Add Product', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.white,
        elevation: 6,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXXXL),
              decoration: const BoxDecoration(
                color: AppTheme.lightGray,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 80,
                color: AppTheme.mediumGray,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            Text(
              'No Products Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Add products to start tracking inventory',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXXXL),
            ElevatedButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Product'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final productInfo = product['products'] as Map<String, dynamic>;
        final stock = product['current_stock'] as int? ?? 0;
        final threshold = product['low_stock_threshold'] as int? ?? 10;
        final isLowStock = stock <= threshold && stock > 0;
        final isOutOfStock = stock == 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: Container(
            padding: AppTheme.paddingXXL,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOutOfStock
                    ? AppTheme.errorRed.withValues(alpha: 0.3)
                    : isLowStock
                        ? AppTheme.warningOrange.withValues(alpha: 0.3)
                        : AppTheme.mediumGray.withValues(alpha: 0.5),
                width: isOutOfStock || isLowStock ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        productInfo['name'] ?? 'Product',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    ElevatedButton.icon(
                      onPressed: () => _showEditProductDialog(product),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cost of one can : Rs. ${(product['selling_price'] as num).toStringAsFixed(0)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    // Status Badge
                    if (isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel_rounded, size: 14, color: AppTheme.white),
                            SizedBox(width: 4),
                            Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_rounded,
                                size: 14, color: AppTheme.white),
                            SizedBox(width: 4),
                            Text(
                              'Low Stock',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingL),

                // Stock Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? AppTheme.errorRed.withValues(alpha: 0.08)
                        : isLowStock
                            ? AppTheme.warningOrange.withValues(alpha: 0.08)
                            : AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Stock',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            '$stock cans',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: isOutOfStock
                                      ? AppTheme.errorRed
                                      : isLowStock
                                          ? AppTheme.warningOrange
                                          : AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Alert at',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacingXS),
                          Text(
                            '$threshold cans',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showUpdateStockDialog(product),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Update Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final depositController = TextEditingController();
    final stockController = TextEditingController();
    final thresholdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const Text(
                'Product Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., 20L Water Can',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              const Text(
                'Selling Price',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter price',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deposit Amount (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Refundable deposit per can (0 if none)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: depositController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter deposit amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Initial Stock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Enter number of cans',
                  suffixText: 'cans',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Low Stock Threshold',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Alert when stock falls below this number',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Enter threshold number',
                  suffixText: 'cans',
                  border: OutlineInputBorder(),
                ),
              ),
              ],
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim());
              final deposit =
                  double.tryParse(depositController.text.trim()) ?? 0.0;
              final stock = int.tryParse(stockController.text.trim()) ?? 0;
              final threshold =
                  int.tryParse(thresholdController.text.trim()) ?? 10;

              if (name.isEmpty || price == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please enter a valid name and selling price'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }

              await _createProduct(
                name: name,
                price: price,
                deposit: deposit,
                initialStock: stock,
                threshold: threshold,
              );

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(Map<String, dynamic> product) {
    final stockController = TextEditingController();
    bool isAdding = true;
    int changeAmount = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Update Stock: ${product['products']['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Current Stock Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Stock:'),
                    Text(
                      '${product['current_stock']} cans',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add/Reduce Toggle
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          isAdding = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAdding
                            ? AppTheme.successGreen
                            : AppTheme.lightGray,
                        foregroundColor: isAdding
                            ? AppTheme.white
                            : AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 24,
                            color: isAdding
                                ? AppTheme.white
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add\nStock',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          isAdding = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isAdding
                            ? AppTheme.errorRed
                            : AppTheme.lightGray,
                        foregroundColor: !isAdding
                            ? AppTheme.white
                            : AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_rounded,
                            size: 24,
                            color: !isAdding
                                ? AppTheme.white
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Reduce\nStock',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Amount Input
              Text(
                isAdding ? 'Cans to Add' : 'Cans to Reduce',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter number of cans',
                  suffixText: 'cans',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    isAdding
                        ? Icons.add_circle_rounded
                        : Icons.remove_circle_rounded,
                    color: isAdding ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    changeAmount = int.tryParse(value) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Preview
              if (changeAmount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdding
                        ? AppTheme.successGreen.withValues(alpha: 0.1)
                        : AppTheme.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('New Stock:'),
                      Text(
                        '${isAdding ? (product['current_stock'] as int) + changeAmount : (product['current_stock'] as int) - changeAmount} cans',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isAdding
                              ? AppTheme.successGreen
                              : AppTheme.errorRed,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: changeAmount > 0
                  ? () async {
                      final currentStock = product['current_stock'] as int;
                      final newStock = isAdding
                          ? currentStock + changeAmount
                          : currentStock - changeAmount;

                      if (newStock < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot reduce stock below 0'),
                            backgroundColor: AppTheme.errorRed,
                          ),
                        );
                        return;
                      }

                      await _updateStock(product['id'], newStock);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  : null,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final priceController = TextEditingController();
    final depositController = TextEditingController();
    final thresholdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit: ${product['products']['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selling Price',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter price',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deposit Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Refundable deposit per can',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: depositController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter deposit amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Low Stock Threshold',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Alert when stock falls below this number',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Enter threshold',
                  suffixText: 'cans',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(priceController.text);
              final deposit = double.tryParse(depositController.text);
              final threshold = int.tryParse(thresholdController.text);

              if (price != null && deposit != null && threshold != null) {
                await _updateProductSettings(
                    product['id'], price, deposit, threshold);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStock(String productId, int newStock) async {
    try {
      await _supabase
          .from('vendor_products')
          .update({'current_stock': newStock}).eq('id', productId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock updated successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      _loadInventory();
    } catch (e) {
      print('❌ Error updating stock: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update stock'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _updateProductSettings(
      String productId, double price, double deposit, int threshold) async {
    try {
      await _supabase.from('vendor_products').update({
        'selling_price': price,
        'deposit_amount': deposit,
        'low_stock_threshold': threshold,
      }).eq('id', productId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product settings updated!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      _loadInventory();
    } catch (e) {
      print('❌ Error updating product: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  /// Create a new product for this vendor.
  ///
  /// This will:
  /// 1. Insert into `products` table (name only)
  /// 2. Insert into `vendor_products` with pricing + stock
  Future<void> _createProduct({
    required String name,
    required double price,
    required double deposit,
    required int initialStock,
    required int threshold,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId ??
          '5d4b8601-2bef-4ce3-8631-b62730d403ea';

      // 1. Create / ensure a product record
      final productInsert = await _supabase
          .from('products')
          .insert({'name': name}).select().single();

      final productId = productInsert['id'] as String;

      // 2. Link it to this vendor with pricing and inventory info
      await _supabase.from('vendor_products').insert({
        'vendor_id': vendorId,
        'product_id': productId,
        'selling_price': price,
        'deposit_amount': deposit,
        'current_stock': initialStock,
        'low_stock_threshold': threshold,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }

      _loadInventory();
    } catch (e) {
      print('❌ Error creating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add product'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
