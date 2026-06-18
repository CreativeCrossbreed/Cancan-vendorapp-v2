import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/vendor_data_service.dart';
import '../../../utils/localization_extension.dart';
import '../../auth/login_screen.dart';
import '../../qr_code/qr_code_screen.dart';
import '../../catalog/product_catalog_screen.dart';
import '../../settings/settings_screen.dart';
import '../../vacation/vacation_mode_screen.dart';

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
                        _vendorData?['name'] ?? context.tr('vendor'),
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
                        icon: Icons.storefront_rounded,
                        title: context.tr('product_catalog'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductCatalogScreen(),
                            ),
                          );
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
                        icon: Icons.analytics_rounded,
                        title: context.tr('analytics'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(context.tr('analytics_coming_soon'))),
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
                      const Divider(height: 32),
                      _buildMenuItem(
                        icon: Icons.logout_rounded,
                        title: context.tr('logout'),
                        color: AppTheme.errorRed,
                        onTap: () => _handleLogout(context),
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
    final nameController = TextEditingController(text: _vendorData?['name'] ?? '');
    final businessNameController = TextEditingController(text: _vendorData?['business_name'] ?? '');
    final addressController = TextEditingController(text: _vendorData?['address'] ?? '');
    bool isEditing = false;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      context.tr('business_details'),
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!isEditing) ...[
                _buildDetailItem(context.tr('vendor_name'), _vendorData?['name'] ?? context.tr('not_available')),
                _buildDetailItem(
                    context.tr('business_name'), _vendorData?['business_name'] ?? context.tr('not_available')),
                _buildDetailItem(context.tr('phone_number'), _vendorData?['phone'] ?? context.tr('not_available')),
                _buildDetailItem(context.tr('address'), _vendorData?['address'] ?? context.tr('not_available')),
              ] else ...[
                Text(
                  context.tr('vendor_name'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: context.tr('enter_vendor_name'),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('business_name'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: businessNameController,
                  decoration: InputDecoration(
                    hintText: context.tr('enter_business_name'),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                _buildDetailItem(context.tr('phone_number'), _vendorData?['phone'] ?? context.tr('not_available')),
                const SizedBox(height: 16),
                Text(
                  context.tr('address'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    hintText: context.tr('enter_address'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.words,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              if (isEditing) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mediumGray,
                        foregroundColor: AppTheme.white,
                      ),
                      child: Text(context.tr('close')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!isEditing) {
                                setState(() => isEditing = true);
                              } else {
                                // Save changes
                                setState(() => isSaving = true);
                                try {
                                  final result = await VendorDataService.updateProfile(
                                    name: nameController.text.trim(),
                                    businessName: businessNameController.text.trim(),
                                    address: addressController.text.trim(),
                                  );

                                  if (!context.mounted) return;

                                  if (result['success']) {
                                    await VendorDataService.clearCache();
                                    await _loadVendorData();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(context.tr('business_details_updated')),
                                          backgroundColor: AppTheme.successGreen,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(result['message'] ?? context.tr('failed_update_business_details')),
                                          backgroundColor: AppTheme.errorRed,
                                        ),
                                      );
                                    }
                                    setState(() => isSaving = false);
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(context.tr('something_went_wrong')),
                                        backgroundColor: AppTheme.errorRed,
                                      ),
                                    );
                                  }
                                  setState(() => isSaving = false);
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.white,
                              ),
                            )
                          : Text(isEditing ? context.tr('save') : context.tr('edit')),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
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

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
