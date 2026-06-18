import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../home/widgets/app_drawer.dart';

/// Notifications Settings Screen
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _orderNotifications = true;
  bool _paymentNotifications = true;
  bool _lowStockNotifications = true;
  bool _marketingNotifications = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orderNotifications = prefs.getBool('notif_orders') ?? true;
      _paymentNotifications = prefs.getBool('notif_payments') ?? true;
      _lowStockNotifications = prefs.getBool('notif_low_stock') ?? true;
      _marketingNotifications = prefs.getBool('notif_marketing') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_orders', _orderNotifications);
    await prefs.setBool('notif_payments', _paymentNotifications);
    await prefs.setBool('notif_low_stock', _lowStockNotifications);
    await prefs.setBool('notif_marketing', _marketingNotifications);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification preferences saved'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildNotificationTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'New Orders',
                  subtitle: 'Get notified when customers place new orders',
                  value: _orderNotifications,
                  onChanged: (value) => setState(() => _orderNotifications = value),
                ),
                _buildNotificationTile(
                  icon: Icons.payment_outlined,
                  title: 'Payment Reminders',
                  subtitle: 'Reminders for pending payments',
                  value: _paymentNotifications,
                  onChanged: (value) => setState(() => _paymentNotifications = value),
                ),
                _buildNotificationTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Low Stock Alerts',
                  subtitle: 'Get notified when product stock is low',
                  value: _lowStockNotifications,
                  onChanged: (value) => setState(() => _lowStockNotifications = value),
                ),
                _buildNotificationTile(
                  icon: Icons.campaign_outlined,
                  title: 'Marketing & Updates',
                  subtitle: 'Promotional offers and app updates',
                  value: _marketingNotifications,
                  onChanged: (value) => setState(() => _marketingNotifications = value),
                ),
              ],
            ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

