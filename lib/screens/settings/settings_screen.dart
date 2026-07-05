import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_data_service.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/screen_with_nav.dart';
import '../../widgets/business_details_sheet.dart';
import '../auth/login_screen.dart';
import '../home/widgets/app_drawer.dart';
import 'notifications_settings_screen.dart';
import 'working_hours_screen.dart';
import '../auth/payout_details_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

/// Settings Screen - Preferences. Profile editing lives in the shared
/// Business Details sheet (also reachable from the drawer) — this screen
/// just links to it rather than duplicating the edit form.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  String _selectedLanguage = 'en'; // Default to English

  Map<String, dynamic>? _vendorData;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language') ?? 'en';
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  Future<void> _loadVendorData() async {
    setState(() => _isLoading = true);

    try {
      // Use cached data - no API call if cache is valid
      final data = await VendorDataService.getVendorProfile();
      setState(() {
        _vendorData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading vendor data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNav(
      title: context.tr('settings'),
      drawer: const AppDrawer(),
      currentNavIndex: 0,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section — tap opens the shared Business Details sheet.
                  InkWell(
                    onTap: () => showBusinessDetailsSheet(
                      context: context,
                      vendorData: _vendorData,
                      onUpdated: _loadVendorData,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              size: 40,
                              color: AppTheme.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _vendorData?['name'] ?? context.tr('business_name'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _vendorData?['phone'] ?? '',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.white.withValues(alpha: 0.9),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('edit'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.white.withValues(alpha: 0.75),
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('settings'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingTile(
                          icon: Icons.notifications_rounded,
                          title: context.tr('notifications'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingTile(
                          icon: Icons.schedule_rounded,
                          title: context.tr('working_hours'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WorkingHoursScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingTile(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Bank / UPI Details',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PayoutDetailsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingTile(
                          icon: Icons.language_rounded,
                          title: context.tr('change_language'),
                          subtitle: _selectedLanguage == 'ta' ? context.tr('tamil') : context.tr('english'),
                          onTap: _showLanguageDialog,
                        ),
                        _buildSettingTile(
                          icon: Icons.privacy_tip_rounded,
                          title: 'Privacy Policy',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                        ),
                        _buildSettingTile(
                          icon: Icons.description_rounded,
                          title: 'Terms of Service',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TermsOfServiceScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 32),
                        _buildSettingTile(
                          icon: Icons.logout_rounded,
                          title: context.tr('logout'),
                          color: AppTheme.errorRed,
                          onTap: () => _handleLogout(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? AppTheme.textPrimary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color ?? AppTheme.textPrimary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: color ?? AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Each language's own name shown in its own script — not
              // translated through the current locale — so a vendor who
              // accidentally switched to a language they can't read can
              // still recognize their own language to switch back.
              RadioListTile<String>(
                title: const Text('தமிழ்'),
                value: 'ta',
                groupValue: _selectedLanguage,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _selectedLanguage = value);
                    await _saveLanguage(value);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: _selectedLanguage,
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _selectedLanguage = value);
                    await _saveLanguage(value);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLanguage(String languageCode) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    await localeProvider.setLocale(languageCode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('language_changed')),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
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
