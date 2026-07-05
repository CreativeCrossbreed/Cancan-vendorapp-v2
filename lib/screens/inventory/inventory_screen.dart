import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../utils/localization_extension.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);

    try {
      // Get vendor ID
      final vendorId = SupabaseConfig.currentVendorId;

      if (vendorId == null) {
        throw Exception('No vendor ID found. Please login again.');
      }

      // Fetch vendor products with product details. Filters out soft-deleted
      // products (is_active=false) — same flag the WhatsApp catalog checks,
      // so a deleted product disappears from both surfaces at once.
      final response = await _supabase
          .from('vendor_products')
          .select('''
            *,
            products(id, name)
          ''')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('❌ Error loading inventory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('failed_load_inventory')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Flat minimal header (no gradient)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppTheme.textPrimary),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('inventory'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        context.tr('track_water_cans_stock'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add_rounded, color: AppTheme.textPrimary),
        label: const Text('Add Product',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 1,
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
      padding: AppTheme.screenPadding,
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final productInfo = product['products'] as Map<String, dynamic>;
        final stock = product['current_stock'] as int? ?? 0;
        final threshold = product['low_stock_threshold'] as int? ?? 10;
        final price = (product['selling_price'] as num?)?.toDouble() ?? 0;
        final isLowStock = stock <= threshold && stock > 0;
        final isOutOfStock = stock == 0;

        final Color statusColor = isOutOfStock
            ? AppTheme.errorRed
            : isLowStock
                ? AppTheme.warningOrange
                : AppTheme.successGreen;
        final String statusLabel = isOutOfStock
            ? 'Out of stock'
            : isLowStock
                ? 'Low stock'
                : 'In stock';

        // Clean card style matching the rest of the app (Customers, Analytics):
        // white, radius 12, subtle mediumGray border, no heavy shadows.
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.mediumGray),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + status + edit
              Row(
                children: [
                  Expanded(
                    child: Text(
                      productInfo['name'] ?? 'Product',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _statusChip(statusLabel, statusColor),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showEditProductDialog(product),
                  ),
                ],
              ),
              Text(
                'Rs. ${price.toStringAsFixed(0)} per can',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Stock stats
              Row(
                children: [
                  Expanded(
                    child: _statBox('Current stock', '$stock cans', statusColor),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _statBox('Alert at', '$threshold cans', AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Update stock action (uses themed primary button)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateStockDialog(product),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Update Stock'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Small pill status chip (matches the chip style used on other screens).
  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  /// A labelled stat box (current stock / alert threshold).
  Widget _statBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: valueColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
    final productInfo = product['products'] as Map<String, dynamic>;
    final nameController = TextEditingController(text: productInfo['name'] as String? ?? '');
    final priceController = TextEditingController(
      text: ((product['selling_price'] as num?) ?? 0).toString(),
    );
    final depositController = TextEditingController(
      text: ((product['deposit_amount'] as num?) ?? 0).toString(),
    );
    final thresholdController = TextEditingController(
      text: ((product['low_stock_threshold'] as num?) ?? 10).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit: ${productInfo['name']}'),
        content: SingleChildScrollView(
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
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteProduct(product);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text);
                  final deposit = double.tryParse(depositController.text);
                  final threshold = int.tryParse(thresholdController.text);

                  if (name.isEmpty || price == null || deposit == null || threshold == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid values for all fields'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                    return;
                  }

                  await _updateProductSettings(
                    productId: product['id'] as String,
                    sharedProductId: productInfo['id'] as String,
                    name: name,
                    price: price,
                    deposit: deposit,
                    threshold: threshold,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
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
      debugPrint('❌ Error updating stock: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('failed_update_stock')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _updateProductSettings({
    required String productId,
    required String sharedProductId,
    required String name,
    required double price,
    required double deposit,
    required int threshold,
  }) async {
    try {
      // _createProduct always inserts a fresh `products` row per vendor
      // (never reuses an existing one — see _createProduct below), so in
      // practice each vendor_products row owns a dedicated products row.
      // Renaming it here is safe and won't rename another vendor's product.
      await _supabase.from('products').update({'name': name}).eq('id', sharedProductId);

      await _supabase.from('vendor_products').update({
        'selling_price': price,
        'deposit_amount': deposit,
        'low_stock_threshold': threshold,
      }).eq('id', productId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('product_settings_updated')),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      _loadInventory();
    } catch (e) {
      debugPrint('❌ Error updating product: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('failed_update_product')),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _confirmDeleteProduct(Map<String, dynamic> product) {
    final productInfo = product['products'] as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Remove "${productInfo['name']}" from your catalogue? '
          'It will no longer be offered to customers on WhatsApp. '
          'Past orders for this product are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product['id'] as String);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Soft-delete: flips vendor_products.is_active to false rather than
  /// hard-deleting the row. order_items.product_id is ON DELETE RESTRICT,
  /// so a hard delete would fail outright for any product with order
  /// history — and even without that constraint, erasing the row would
  /// orphan historical order/payment records. is_active=false is also
  /// exactly what the WhatsApp catalog query filters on, so this is the
  /// same flag that already controls whether customers can pick it.
  Future<void> _deleteProduct(String productId) async {
    try {
      await _supabase
          .from('vendor_products')
          .update({'is_active': false}).eq('id', productId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product removed from catalogue'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      _loadInventory();
    } catch (e) {
      debugPrint('❌ Error deleting product: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete product'),
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
      final vendorId = SupabaseConfig.currentVendorId;

      if (vendorId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No vendor ID found. Please login again.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }

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
      debugPrint('❌ Error creating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
