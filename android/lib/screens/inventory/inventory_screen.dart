import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../utils/logger.dart';
import '../home/widgets/app_drawer.dart';
import '../../services/inventory_service.dart';

/// Inventory Screen - Manage stock levels with comprehensive tracking
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final _inventoryService = InventoryService();
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  Map<String, dynamic> _statistics = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait<dynamic>([
        _inventoryService.getVendorProducts(),
        _inventoryService.getLowStockProducts(),
        _inventoryService.getInventoryStatistics(),
      ]);

      setState(() {
        _products = results[0] as List<Map<String, dynamic>>;
        _lowStockProducts = results[1] as List<Map<String, dynamic>>;
        _statistics = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });

      AppLogger.i('✅ Loaded ${_products.length} products, ${_lowStockProducts.length} low stock');
    } catch (e) {
      AppLogger.e('❌ Error loading inventory: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Inventory Management'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddProductDialog,
            tooltip: 'Add Product',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          if (!_isLoading) _buildStatisticsCards(),
          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'All Products'),
              Tab(text: 'Low Stock'),
              Tab(text: 'Statistics'),
            ],
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllProductsTab(),
                _buildLowStockTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryBlue.withOpacity(0.05),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Products',
              '${_statistics['totalProducts'] ?? 0}',
              Icons.inventory_2_outlined,
              AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              '${_statistics['lowStockProducts'] ?? 0}',
              Icons.warning_amber_outlined,
              AppTheme.warningOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Value',
              'Rs.${(_statistics['totalValue'] ?? 0.0).toStringAsFixed(0)}',
              Icons.currency_rupee_outlined,
              AppTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllProductsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) => _buildProductCard(_products[index]),
      ),
    );
  }

  Widget _buildLowStockTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lowStockProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.successGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'No low stock products',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.successGreen,
              ),
            ),
            Text(
              'All products have adequate stock levels',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lowStockProducts.length,
        itemBuilder: (context, index) => _buildProductCard(
          _lowStockProducts[index],
          isLowStock: true,
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailedStatsCard(),
          const SizedBox(height: 20),
          _buildStockHealthIndicator(),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsCard() {
    final totalProducts = _statistics['totalProducts'] ?? 0;
    final lowStockProducts = _statistics['lowStockProducts'] ?? 0;
    final totalStock = _statistics['totalStock'] ?? 0;
    final totalValue = (_statistics['totalValue'] ?? 0.0) as double;
    final lowStockPercentage = (_statistics['lowStockPercentage'] ?? 0.0) as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatRow('Total Products', totalProducts.toString()),
          _buildStatRow('Low Stock Items', lowStockProducts.toString()),
          _buildStatRow('Total Stock Units', totalStock.toString()),
          _buildStatRow('Total Inventory Value', 'Rs.${totalValue.toStringAsFixed(0)}'),
          _buildStatRow('Low Stock Percentage', '${lowStockPercentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockHealthIndicator() {
    final lowStockPercentage = (_statistics['lowStockPercentage'] ?? 0.0) as double;
    Color color;
    String status;
    IconData icon;

    if (lowStockPercentage == 0) {
      color = AppTheme.successGreen;
      status = 'Excellent';
      icon = Icons.sentiment_very_satisfied;
    } else if (lowStockPercentage <= 20) {
      color = AppTheme.warningOrange;
      status = 'Good';
      icon = Icons.sentiment_satisfied;
    } else {
      color = AppTheme.errorRed;
      status = 'Critical';
      icon = Icons.sentiment_very_dissatisfied;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            'Stock Health: $status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Low stock items represent ${lowStockPercentage.toStringAsFixed(1)}% of your inventory',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, {bool isLowStock = false}) {
    final productName = product['products']?['name'] ?? 'Unknown Product';
    final currentStock = product['current_stock'] ?? 0;
    final lowStockThreshold = product['low_stock_threshold'] ?? 10;
    final sellingPrice = (product['selling_price'] ?? 0.0) as double;
    final isActuallyLowStock = currentStock <= lowStockThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActuallyLowStock ? AppTheme.errorRed.withOpacity(0.3) : AppTheme.mediumGray.withOpacity(0.3),
          width: isActuallyLowStock ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs.${sellingPrice.toStringAsFixed(0)} per can',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActuallyLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Low Stock',
                        style: TextStyle(
                          color: AppTheme.errorRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStockInfo(
                  'Current Stock',
                  currentStock.toString(),
                  isActuallyLowStock ? AppTheme.errorRed : AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStockInfo(
                  'Low Stock Alert',
                  'Below $lowStockThreshold',
                  AppTheme.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateStockDialog(product),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Update Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showProductOptions(product),
                  icon: const Icon(Icons.more_horiz),
                  label: const Text('Options'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
              'Add products to start tracking inventory',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddProductDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Product'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final depositController = TextEditingController(text: '0');
    final stockController = TextEditingController(text: '0');
    final thresholdController = TextEditingController(text: '10');

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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'e.g., 20L Water Can',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Selling Price',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: depositController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount (optional)',
                  prefixText: 'Rs. ',
                  helperText: 'Refundable deposit per can (0 if none)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Initial Stock',
                  suffixText: 'cans',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Low Stock Threshold',
                  suffixText: 'cans',
                  helperText: 'Alert when stock falls below this number',
                  border: OutlineInputBorder(),
                ),
              ),
              ],
            ),
          ),
        ),
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
    final stockController = TextEditingController(
      text: (product['current_stock'] as int? ?? 0).toString(),
    );
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
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Add Stock'),
                    icon: Icon(Icons.add, size: 18),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Reduce Stock'),
                    icon: Icon(Icons.remove, size: 18),
                  ),
                ],
                selected: {isAdding},
                onSelectionChanged: (Set<bool> selection) {
                  setDialogState(() {
                    isAdding = selection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: isAdding ? 'Cans to Add' : 'Cans to Reduce',
                  suffixText: 'cans',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    isAdding
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
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
    final priceController = TextEditingController(
      text: (product['selling_price'] as num).toString(),
    );
    final depositController = TextEditingController(
      text: (product['deposit_amount'] as num?)?.toString() ?? '0',
    );
    final thresholdController = TextEditingController(
      text: (product['low_stock_threshold'] as int).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit: ${product['products']['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Selling Price',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: depositController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                  helperText: 'Refundable deposit per can',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: thresholdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Low Stock Threshold',
                  suffixText: 'cans',
                  border: OutlineInputBorder(),
                  helperText: 'Alert when stock falls below this number',
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock updated successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      _loadInventory();
    } catch (e) {
      print('❌ Error updating stock: $e');
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product settings updated!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      _loadInventory();
    } catch (e) {
      print('❌ Error updating product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _toggleAvailability(Map<String, dynamic> product) async {
    final isAvailable = product['is_available'] as bool;

    try {
      await _supabase
          .from('vendor_products')
          .update({'is_available': !isAvailable}).eq('id', product['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAvailable
                ? 'Product hidden from customers'
                : 'Product visible to customers',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      _loadInventory();
    } catch (e) {
      print('❌ Error toggling availability: $e');
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

  void _showProductOptions(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                _showEditProductDialog(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
              title: const Text('Delete Product', style: TextStyle(color: AppTheme.errorRed)),
              onTap: () {
                Navigator.pop(context);
                // Show delete confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Product'),
                    content: const Text('Are you sure you want to delete this product?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await _supabase
                                .from('vendor_products')
                                .delete()
                                .eq('id', product['id']);
                            _loadInventory();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to delete product')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
