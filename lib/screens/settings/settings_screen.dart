import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/locale_provider.dart';
import '../../services/vendor_data_service.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/screen_with_nav.dart';
import '../home/widgets/app_drawer.dart';
import 'notifications_settings_screen.dart';
import 'working_hours_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

/// Settings Screen - Manage vendor profile and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedLanguage = 'ta'; // Default to Tamil

  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();

  Map<String, dynamic>? _vendorData;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language') ?? 'ta';
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorData() async {
    setState(() => _isLoading = true);

    try {
      // Use cached data - no API call if cache is valid
      final data = await VendorDataService.getVendorProfile();

      if (data != null) {
        setState(() {
          _vendorData = data;
          _nameController.text = data['name'] ?? '';
          _businessNameController.text = data['business_name'] ?? '';
          _addressController.text = data['address'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading vendor data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final result = await VendorDataService.updateProfile(
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('success')),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? context.tr('error')),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('try_again_later')),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNav(
      title: context.tr('settings'),
      drawer: const AppDrawer(),
      currentNavIndex: 0,
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              context.tr('save'),
              style: TextStyle(
                color: _isSaving
                    ? AppTheme.white.withValues(alpha: 0.5)
                    : AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  Container(
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _vendorData?['phone'] ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppTheme.white.withValues(alpha: 0.9),
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Form Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('business_name'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Your Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: context.tr('name'),
                              prefixIcon: const Icon(Icons.person_rounded),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.tr('name');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Business Name
                          TextFormField(
                            controller: _businessNameController,
                            decoration: InputDecoration(
                              labelText: context.tr('business_name'),
                              prefixIcon: const Icon(Icons.business_rounded),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.tr('business_name');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Address
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: context.tr('address'),
                              prefixIcon: const Icon(Icons.location_on_rounded),
                            ),
                            maxLines: 3,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.tr('address');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Other Settings
                          Text(
                            context.tr('settings'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),

                          _buildSettingTile(
                            icon: Icons.notifications_rounded,
                            title: context.tr('notifications'),
                            subtitle: context.tr('notifications'),
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
                            icon: Icons.language_rounded,
                            title: context.tr('change_language'),
                            subtitle: _selectedLanguage,
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
                        ],
                      ),
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
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.lightGray.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textSecondary,
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
              RadioListTile<String>(
                title: Text(context.tr('tamil')),
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
                title: Text(context.tr('english')),
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
}
