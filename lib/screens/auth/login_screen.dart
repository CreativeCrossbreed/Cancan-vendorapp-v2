import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../utils/localization_extension.dart';
import 'otp_screen.dart';

/// Login Screen - Phone Number Entry
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final result =
          await authService.sendOTP(phoneNumber: _phoneController.text);

      if (!mounted) return;

      if (result['success']) {
        // Navigate to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(phoneNumber: _phoneController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? context.tr('error'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('server_error'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48, // matches the 24px padding on each side above
              ),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Brand Section
                Image.asset(
                  'assets/images/Can Can [Logo].png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.water_drop_rounded,
                      size: 80,
                      color: AppTheme.white,
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('app_name'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 60),

                // Phone Input Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('login'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your registered mobile number',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Phone Number Input
                      Text(
                        context.tr('phone'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: '9876543210',
                          prefixIcon: Icon(Icons.phone_outlined),
                          prefixText: '+91 ',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Send OTP Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendOTP,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.white,
                                ),
                              )
                            : Text(context.tr('login')),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                if (kDebugMode) ...[
                  // TEST MODE INDICATOR
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningOrange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.science_outlined,
                          color: AppTheme.warningOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'DEV: Use OTP 000000 (simulated, no SMS needed)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Support Text
                Text(
                  'Having trouble logging in?\nContact support at support@cancanindia.com',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.white.withValues(alpha: 0.8),
                      ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}