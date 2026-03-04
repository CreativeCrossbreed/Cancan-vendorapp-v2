import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'session_service.dart';
import '../utils/logger.dart';

/// Authentication Service - Handles phone OTP authentication
///
/// Dev/test modes are ONLY active in debug builds (stripped from release).
class AuthService {
  final _supabase = SupabaseConfig.client;

  // ── Dev/test flags — gated behind kDebugMode ──────────────────
  // In release builds these are constant `false`, so the compiler
  // tree-shakes all dev/test code paths entirely.
  static final bool _testMode = kDebugMode;
  static final bool _devMode = kDebugMode;
  static const String _testOTP = '123456';
  static const String _devPhoneNumber = '1111111111';
  static const String _devVendorId = 'dev-vendor-123';

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {
    // TEST MODE — debug builds only
    if (_testMode) {
      AppLogger.d('TEST MODE: OTP would be sent to +91$phoneNumber');
      AppLogger.d('TEST MODE: Use OTP: $_testOTP');

      await Future<void>.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'OTP sent successfully (TEST MODE)',
        'testMode': true,
        // NOTE: Never expose the OTP in the response in production
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
      AppLogger.e('Failed to send OTP: $e');
      String errorMessage = 'Failed to send OTP. Please try again.';

      final errorStr = e.toString();
      if (errorStr.contains('invalid_request_format')) {
        errorMessage =
            'Invalid phone number format. Please enter a valid 10-digit number.';
      } else if (errorStr.contains('over_sms_send_rate_limit')) {
        errorMessage =
            'Too many OTP requests. Please wait a few minutes before trying again.';
      } else if (errorStr.contains('Invalid login credentials')) {
        errorMessage =
            'Supabase configuration error. Please check your environment variables.';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Verify OTP and sign in
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    // DEV MODE — debug builds only
    if (_devMode && phoneNumber == _devPhoneNumber) {
      AppLogger.d('DEV MODE: Auto-login for phone $phoneNumber');

      await SessionService.saveSession(
        vendorId: _devVendorId,
        vendorPhone: '+91$phoneNumber',
        hasProfile: true,
      );

      return {
        'success': true,
        'message': 'Login successful (DEV MODE)',
        'hasProfile': true,
        'vendorId': _devVendorId,
      };
    }

    // TEST MODE — debug builds only
    if (_testMode) {
      AppLogger.d('TEST MODE: Verifying OTP for +91$phoneNumber');

      if (otp == _testOTP) {
        await Future<void>.delayed(const Duration(seconds: 1));

        await SessionService.saveSession(
          vendorId: _devVendorId,
          vendorPhone: '+91$phoneNumber',
          hasProfile: true,
        );

        return {
          'success': true,
          'message': 'Login successful (TEST MODE)',
          'hasProfile': true,
          'vendorId': _devVendorId,
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid OTP',
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

        await SessionService.saveSession(
          vendorId: response.user!.id,
          vendorPhone: fullNumber,
          hasProfile: vendorData != null,
        );

        return {
          'success': true,
          'message': 'Login successful',
          'hasProfile': vendorData != null,
        };
      }

      return {
        'success': false,
        'message': 'Invalid OTP',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Verification failed. Please try again.',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await SessionService.clearSession();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null || SessionService.hasSession;

  /// Get current vendor ID
  String? get currentVendorId {
    final userId = currentUser?.id;
    if (userId != null) return userId;
    return SessionService.vendorId;
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
