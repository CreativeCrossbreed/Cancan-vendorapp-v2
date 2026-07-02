import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/vendor_service.dart';
import '../../services/vendor_data_service.dart';
import '../../services/push_notification_service.dart';
import '../home/home_screen.dart';
import '../settings/working_hours_screen.dart';

/// Profile Setup Screen - First-time vendor registration
class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;

  const ProfileSetupScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();

  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('💼 Saving vendor profile...');

      final latitude = double.tryParse(_latitudeController.text.trim());
      final longitude = double.tryParse(_longitudeController.text.trim());
      if (latitude == null || longitude == null) {
        _showError('Please enter valid latitude and longitude values.');
        return;
      }

      final result = await _vendorService.createVendorProfile(
        phone: widget.phoneNumber,
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        address: _addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      debugPrint('📊 Result: ${result['success']}');
      debugPrint('📊 Message: ${result['message']}');
      debugPrint('📊 Vendor ID: ${result['vendorId']}');

      if (result['success']) {
        final vendorId = result['vendorId'] as String;

        debugPrint('✅ Vendor profile created with ID: $vendorId');

        // Clear and refresh cache with new vendor data
        await VendorDataService.clearCache();
        await VendorDataService.initialize(forceRefresh: true); // Force refresh from database
        debugPrint('✅ Vendor data cache refreshed');

        await PushNotificationService.initialize();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile created successfully!'),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 2),
            ),
          );

          // First-time setup continues with working hours before landing on Home.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => WorkingHoursScreen(
                isOnboarding: true,
                onComplete: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            (route) => false,
          );
        }
      } else {
        _showError(result['message'] ?? 'Failed to create profile');
      }
    } catch (e) {
      debugPrint('❌ Exception in _saveProfile: $e');
      _showError('Something went wrong: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 60,
                      color: AppTheme.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Can Can!',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s set up your vendor profile',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),

              // Form Section
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Business Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 24),

                          // Your Name
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              hintText: 'e.g., Rajesh Kumar',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Business Name
                          TextFormField(
                            controller: _businessNameController,
                            decoration: const InputDecoration(
                              labelText: 'Business Name',
                              hintText: 'e.g., Rajesh Water Supply',
                              prefixIcon: Icon(Icons.business_outlined),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your business name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Address
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Business Address',
                              hintText: 'e.g., Shop 12, MG Road, Chennai',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            maxLines: 3,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your business address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latitudeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Latitude',
                                    hintText: 'e.g., 12.9716',
                                    prefixIcon: Icon(Icons.my_location_outlined),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final parsed = double.tryParse(value.trim());
                                    if (parsed == null) {
                                      return 'Invalid';
                                    }
                                    if (parsed < -90 || parsed > 90) {
                                      return '-90 to 90';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _longitudeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Longitude',
                                    hintText: 'e.g., 77.5946',
                                    prefixIcon: Icon(Icons.place_outlined),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final parsed = double.tryParse(value.trim());
                                    if (parsed == null) {
                                      return 'Invalid';
                                    }
                                    if (parsed < -180 || parsed > 180) {
                                      return '-180 to 180';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Info Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Location is required for customer-vendor matching. Add inventory after signup to start receiving orders.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Continue Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.white,
                                    ),
                                  )
                                : const Text('Continue to Dashboard'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
