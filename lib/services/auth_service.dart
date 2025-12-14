import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'session_service.dart';

/// Authentication Service - Handles phone OTP authentication
class AuthService {
  final _supabase = SupabaseConfig.client;

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {

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
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again.',
        'error': e.toString(),
      };
    }
  }

  /// Verify OTP and sign in
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {

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

        // Persist session locally
        await SessionService.saveSession(
          vendorId: response.user!.id,
          vendorPhone: fullNumber,
          hasProfile: vendorData != null,
        );

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
      return {
        'success': false,
        'message': 'Verification failed. Please try again.',
        'error': e.toString(),
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
