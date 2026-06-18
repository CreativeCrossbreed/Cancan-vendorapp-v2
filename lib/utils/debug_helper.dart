import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../config/supabase_config.dart';

/// Debug Helper - Quick tools for testing and debugging
class DebugHelper extends StatefulWidget {
  const DebugHelper({super.key});

  @override
  State<DebugHelper> createState() => _DebugHelperState();
}

class _DebugHelperState extends State<DebugHelper> {
  final _supabase = SupabaseConfig.client;
  String _debugOutput = '';
  bool _isLoading = false;

  void _addDebugLine(String line) {
    setState(() {
      _debugOutput += '$line\n';
    });
  }

  Future<void> _checkVendorInfo() async {
    setState(() {
      _debugOutput = '🔍 Checking Vendor Info...\n\n';
      _isLoading = true;
    });

    try {
      final vendorId = SupabaseConfig.currentVendorId ??
          '5d4b8601-2bef-4ce3-8631-b62730d403ea';
      _addDebugLine('Vendor ID: $vendorId');

      final vendor = await _supabase
          .from('vendors')
          .select()
          .eq('id', vendorId)
          .maybeSingle();

      if (vendor != null) {
        _addDebugLine('✅ Vendor Found!');
        _addDebugLine('Name: ${vendor['name']}');
        _addDebugLine('Business: ${vendor['business_name']}');
        _addDebugLine('Phone: ${vendor['phone']}');
      } else {
        _addDebugLine('❌ Vendor NOT found in database!');
      }
    } catch (e) {
      _addDebugLine('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkTodayOrders() async {
    setState(() {
      _debugOutput = '📦 Checking Today\'s Orders...\n\n';
      _isLoading = true;
    });

    try {
      final vendorId = SupabaseConfig.currentVendorId ??
          '5d4b8601-2bef-4ce3-8631-b62730d403ea';
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      _addDebugLine('Vendor ID: $vendorId');
      _addDebugLine('Date: $dateStr');
      _addDebugLine('');

      final orders = await _supabase
          .from('orders')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('delivery_date', dateStr);

      _addDebugLine('Found ${orders.length} orders for today');
      _addDebugLine('');

      if (orders.isEmpty) {
        _addDebugLine('❌ No orders found!');
        _addDebugLine('');
        _addDebugLine('💡 Solutions:');
        _addDebugLine('1. Run the SQL script to create test data');
        _addDebugLine('2. Check if vendor_id matches');
        _addDebugLine('3. Verify delivery_date format');
      } else {
        for (var order in orders) {
          _addDebugLine('Order: ${order['order_number']}');
          _addDebugLine('Status: ${order['status']}');
          _addDebugLine('Amount: Rs.${order['total_amount']}');
          _addDebugLine('---');
        }
      }
    } catch (e) {
      _addDebugLine('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkCustomers() async {
    setState(() {
      _debugOutput = '👥 Checking Customers...\n\n';
      _isLoading = true;
    });

    try {
      final customers = await _supabase.from('customers').select().limit(10);

      _addDebugLine('Found ${customers.length} customers');
      _addDebugLine('');

      if (customers.isEmpty) {
        _addDebugLine('❌ No customers found!');
        _addDebugLine('You need to add customers to Supabase first.');
      } else {
        for (var customer in customers) {
          _addDebugLine('${customer['name']} - ${customer['phone']}');
        }
      }
    } catch (e) {
      _addDebugLine('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkProducts() async {
    setState(() {
      _debugOutput = '🧴 Checking Products...\n\n';
      _isLoading = true;
    });

    try {
      final vendorId = SupabaseConfig.currentVendorId ??
          '5d4b8601-2bef-4ce3-8631-b62730d403ea';

      final products = await _supabase
          .from('vendor_products')
          .select('*, products(name)')
          .eq('vendor_id', vendorId);

      _addDebugLine('Found ${products.length} products');
      _addDebugLine('');

      if (products.isEmpty) {
        _addDebugLine('❌ No products found!');
      } else {
        for (var product in products) {
          _addDebugLine('${product['products']['name']}');
          _addDebugLine('Stock: ${product['current_stock']}');
          _addDebugLine('Price: Rs.${product['selling_price']}');
          _addDebugLine('---');
        }
      }
    } catch (e) {
      _addDebugLine('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createDummyOrder() async {
    setState(() {
      _debugOutput = '🧪 Creating dummy order...\n\n';
      _isLoading = true;
    });

    try {
      final vendorId = SupabaseConfig.currentVendorId ??
          '5d4b8601-2bef-4ce3-8631-b62730d403ea';

      _addDebugLine('Vendor ID: $vendorId');

      // 1. Get a sample customer
      final customer = await _supabase
          .from('customers')
          .select()
          .limit(1)
          .maybeSingle();

      if (customer == null) {
        _addDebugLine('❌ No customers found. Cannot create dummy order.');
        _addDebugLine('👉 Add at least one customer in Supabase first.');
        return;
      }

      _addDebugLine(
          'Using customer: ${customer['name']} (${customer['phone']})');

      // 2. Get a sample product for this vendor
      final product = await _supabase
          .from('vendor_products')
          .select('id, selling_price, products(id, name)')
          .eq('vendor_id', vendorId)
          .limit(1)
          .maybeSingle();

      if (product == null) {
        _addDebugLine('❌ No vendor_products found for this vendor.');
        _addDebugLine(
            '👉 Add at least one product for the vendor in Supabase first.');
        return;
      }

      final productData = product['products'];
      final productName = productData != null ? productData['name'] : 'Product';
      final productId = productData != null ? productData['id'] : product['id'];
      final unitPrice =
          (product['selling_price'] as num?)?.toDouble() ?? 100.0;
      const quantity = 2;
      final totalAmount = unitPrice * quantity;

      _addDebugLine('Using product: $productName');
      _addDebugLine('Quantity: $quantity, Unit Price: $unitPrice');

      // 3. Create the dummy order
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final orderNumber = 'TEST-${now.millisecondsSinceEpoch}';

      final orderInsert = await _supabase
          .from('orders')
          .insert({
            'order_number': orderNumber,
            'vendor_id': vendorId,
            'customer_id': customer['id'],
            'delivery_date': dateStr,
            'time_slot': '09:00-11:00',
            'total_amount': totalAmount,
            'status': 'pending',
            'is_delivered': false,
            'payment_status': 'unpaid',
            'created_at': now.toIso8601String(),
            'notes': 'Dummy test order from Debug Helper',
          })
          .select()
          .single();

      final orderId = orderInsert['id'] as String;

      _addDebugLine('✅ Order created with ID: $orderId');
      _addDebugLine('Order Number: $orderNumber');

      // 4. Create order item
      await _supabase.from('order_items').insert({
        'order_id': orderId,
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': totalAmount,
      });

      _addDebugLine('✅ Order item created');
      _addDebugLine('');
      _addDebugLine('🎉 Dummy order created successfully for $dateStr');
      _addDebugLine(
          'You should now see this order in Today\'s Orders with status "pending".');
    } catch (e) {
      _addDebugLine('❌ Error creating dummy order: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyOutput() {
    Clipboard.setData(ClipboardData(text: _debugOutput));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug output copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Helper'),
        actions: [
          if (_debugOutput.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyOutput,
              tooltip: 'Copy Output',
            ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.lightGray,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Quick Diagnostics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _checkVendorInfo,
                      icon: const Icon(Icons.person, size: 16),
                      label: const Text('Vendor Info'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _checkTodayOrders,
                      icon: const Icon(Icons.shopping_bag, size: 16),
                      label: const Text('Today\'s Orders'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _checkCustomers,
                      icon: const Icon(Icons.people, size: 16),
                      label: const Text('Customers'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.warningOrange,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _checkProducts,
                      icon: const Icon(Icons.inventory, size: 16),
                      label: const Text('Products'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlueDark,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createDummyOrder,
                      icon: const Icon(Icons.science, size: 16),
                      label: const Text('Create Dummy Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Output Area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _debugOutput.isEmpty
                            ? '👆 Tap a button above to run diagnostics'
                            : _debugOutput,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),

          // Info Footer
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use this tool to diagnose data issues. Run SQL script in Supabase to create test data.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
