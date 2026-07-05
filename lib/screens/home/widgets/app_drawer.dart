import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/vendor_data_service.dart';
import '../../../utils/localization_extension.dart';
import '../../../widgets/business_details_sheet.dart';
import '../../qr_code/qr_code_screen.dart';
import '../../settings/settings_screen.dart';
import '../../vacation/vacation_mode_screen.dart';
import '../../customers/customer_list_screen.dart';

/// App Drawer — clean/minimal side menu matching the admin design.
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
    final data = await VendorDataService.getVendorProfile();
    // The drawer is popped (and its State disposed) before the Business
    // Details sheet opens, since this is also passed as that sheet's
    // onUpdated callback — without this guard, setState here throws after
    // a successful save.
    if (!mounted) return;
    setState(() {
      _vendorData = data;
      _isLoading = data == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _vendorData?['name'] ?? context.tr('vendor');
    final business = (_vendorData?['business_name'] ?? '') as String;

    return Drawer(
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header — logo tile + name + business
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/Can Can [Logo].png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.water_drop_rounded,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${context.tr('hi_greeting')}, $name',
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (business.isNotEmpty)
                                Text(
                                  business,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.completedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 14, color: AppTheme.successGreen),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('verified'),
                          style: const TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const QRCodeScreen()));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.people_alt_rounded,
                    title: context.tr('customers_title'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const CustomerListScreen()));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.beach_access_rounded,
                    title: context.tr('vacation_mode'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const VacationModeScreen()));
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_rounded,
                    title: context.tr('settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: context.tr('support_help'),
                    onTap: () {
                      Navigator.pop(context);
                      _showSupport(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: context.tr('about_can_can'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAbout(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.tr('vendor_app_version'),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
    final tint = color ?? AppTheme.primaryBlueDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: tint),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color ?? AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppTheme.darkGray),
              ],
            ),
          ),
        ),
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
            Row(children: [Icon(Icons.email, size: 20), SizedBox(width: 8), Text('support@cancanindia.com')]),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.phone, size: 20), SizedBox(width: 8), Text('90253 20535')]),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
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
            Text('Can Can Vendor App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text('Streamlining water can delivery management for vendors.'),
            SizedBox(height: 8),
            Text('© 2025 Can Can. All rights reserved.'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
