import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'session_service.dart';

/// Authentication Service - Handles phone OTP authentication
/// Currently in TEST MODE - bypasses real OTP for development
class AuthService {
  final _supabase = SupabaseConfig.client;

  // TEST MODE FLAG - Set to false when ready for production
  static const bool _testMode = true;
  static const String _testOTP = '123456'; // Test OTP for development

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {
    if (_testMode) {
      // TEST MODE: Simulate successful OTP send
      print('🧪 TEST MODE: OTP would be sent to +91$phoneNumber');
      print('🧪 TEST MODE: Use OTP: $_testOTP');

      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay

      return {
        'success': true,
        'message': 'OTP sent successfully',
        'testMode': true,
        'testOTP': _testOTP,
      };
    }

    // PRODUCTION MODE: Real OTP via Supabase
    try {
      final fullNumber =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      await _supabase.auth.signInWithOtp(
        phone: fullNumber,
      );

      return {
        'success': true,
        'message': 'OTP sent successfully',
      };
    } catch (e) {
      print('Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again.',
      };
    }
  }

  /// Verify OTP and sign in
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    if (_testMode) {
      // TEST MODE: Accept test OTP and create mock session
      print('🧪 TEST MODE: Verifying OTP for +91$phoneNumber');

      if (otp == _testOTP) {
        await Future.delayed(
            const Duration(seconds: 1)); // Simulate network delay

        // Create a test vendor ID based on phone number
        final testVendorId =
            'test_vendor_${phoneNumber.replaceAll(RegExp(r'\D'), '')}';

        // Check if vendor profile exists in database
        try {
          final vendorData = await _supabase
              .from('vendors')
              .select()
              .eq('phone', '+91$phoneNumber')
              .maybeSingle();

          print('🧪 TEST MODE: Login successful');
          print('🧪 TEST MODE: Has profile: ${vendorData != null}');

          final vendorId = vendorData?['id'] ?? testVendorId;

          // Persist session locally so we can skip login next time.
          await SessionService.saveSession(
            vendorId: vendorId,
            vendorPhone: '+91$phoneNumber',
            hasProfile: vendorData != null,
          );

          return {
            'success': true,
            'message': 'Login successful',
            'hasProfile': vendorData != null,
            'testMode': true,
            'vendorId': vendorId,
          };
        } catch (e) {
          print('🧪 TEST MODE: Error checking profile: $e');
          return {
            'success': true,
            'message': 'Login successful',
            'hasProfile': false,
            'testMode': true,
            'vendorId': testVendorId,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Invalid OTP. Use: $_testOTP for testing',
        };
      }
    }

    // PRODUCTION MODE: Real OTP verification
    try {
      final fullNumber =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: fullNumber,
        token: otp,
      );

      if (response.user != null) {
        final vendorData = await _supabase
            .from('vendors')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        return {
          'success': true,
          'message': 'Login successful',
          'hasProfile': vendorData != null,
          'user': response.user,
        };
      }

      return {
        'success': false,
        'message': 'Invalid OTP',
      };
    } catch (e) {
      print('Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Verification failed. Please try again.',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    if (_testMode) {
      print('🧪 TEST MODE: Signing out (mock)');
      await SessionService.clearSession();
      return;
    }

    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser {
    if (_testMode) {
      // Return null in test mode - we're not using real auth
      return null;
    }
    return _supabase.auth.currentUser;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    if (_testMode) {
      // In test mode, check if we have a stored session indicator
      return false; // Always show login in test mode
    }
    return currentUser != null;
  }

  /// Get current vendor ID
  String? get currentVendorId {
    if (_testMode) {
      return null; // Handled differently in test mode
    }
    return currentUser?.id;
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
