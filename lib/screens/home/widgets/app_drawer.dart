import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/vendor_data_service.dart';
import '../../../utils/localization_extension.dart';
import '../../../widgets/business_details_sheet.dart';
import '../../qr_code/qr_code_screen.dart';
import '../../settings/settings_screen.dart';
import '../../vacation/vacation_mode_screen.dart';
import '../../customers/customer_list_screen.dart';

/// App Drawer - Side menu with profile and settings
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? _vendorData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    // Use cached data - no API call if cache is valid
    final data = await VendorDataService.getVendorProfile();
    // The drawer is popped (and its State disposed) before the Business
    // Details sheet opens, since this is also passed as that sheet's
    // onUpdated callback — without this guard, setState here throws after
    // a successful save, which the sheet's catch block silently swallows,
    // leaving the sheet stuck open.
    if (!mounted) return;
    setState(() {
      _vendorData = data;
      _isLoading = data == null; // Only show loading if no data at all
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/Can Can [Logo].png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.water_drop_rounded,
                          size: 80,
                          color: AppTheme.white,
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      const CircularProgressIndicator(color: AppTheme.white)
                    else ...[
                      Text(
                        '${context.tr('hi_greeting')}, ${_vendorData?['name'] ?? context.tr('vendor')}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _vendorData?['business_name'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.white.withValues(alpha: 0.9),
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified,
                                size: 16, color: AppTheme.white),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('verified'),
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Menu Items
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildMenuItem(
                        icon: Icons.business_rounded,
                        title: context.tr('business_details'),
                        onTap: () {
                          Navigator.pop(context);
                          _showBusinessDetails(context);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.qr_code_2_rounded,
                        title: context.tr('my_qr_code'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRCodeScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.people_alt_rounded,
                        title: context.tr('customers_title'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.beach_access_rounded,
                        title: context.tr('vacation_mode'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VacationModeScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.settings_rounded,
                        title: context.tr('settings'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 32),
                      _buildMenuItem(
                        icon: Icons.help_rounded,
                        title: context.tr('support_help'),
                        onTap: () {
                          Navigator.pop(context);
                          _showSupport(context);
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.info_rounded,
                        title: context.tr('about_can_can'),
                        onTap: () {
                          Navigator.pop(context);
                          _showAbout(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // App Version
              Container(
                color: AppTheme.white,
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.tr('vendor_app_version'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? AppTheme.textSecondary,
      ),
    );
  }

  void _showBusinessDetails(BuildContext context) {
    showBusinessDetailsSheet(
      context: context,
      vendorData: _vendorData,
      onUpdated: _loadVendorData,
    );
  }

  void _showSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support & Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? Contact us:'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 20),
                SizedBox(width: 8),
                Text('support@cancanindia.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 20),
                SizedBox(width: 8),
                Text('90253 20535'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Can Can'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Can Can Vendor App',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text('Streamlining water can delivery management for vendors.'),
            SizedBox(height: 8),
            Text('© 2025 Can Can. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}
