import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Authentication Service - Handles phone OTP authentication via Supabase
/// Test OTP (000000) supported for development without SMS costs
class AuthService {
  final _supabase = SupabaseConfig.client;

  // Test OTP for development - bypasses real SMS verification
  static const String _testOTP = '000000';

  // This exact phone number is pinned to OTP 000000 in Supabase's own
  // "test phone numbers" Auth setting (Dashboard → Authentication → Sign In
  // / Providers → SMS provider → Test OTPs). Matching must be an EXACT
  // string match against what's configured there — no +91 prefix. Using
  // this real, pre-configured number+OTP pair means test-mode login goes
  // through Supabase's actual OTP verification and gets a real, RLS-valid
  // auth.uid() — unlike a locally-generated fake UUID or anonymous sign-in
  // (which requires an Auth setting this account doesn't have permission
  // to enable). Every test-mode login shares this one underlying identity.
  static const String _testPhoneRaw = '9080126534';

  // In-memory test session (NOT persisted - lost on app restart)
  static Map<String, dynamic>? _testSession;

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {
    try {
      final fullNumber =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      debugPrint('📱 Sending OTP to $fullNumber...');
      if (kDebugMode) {
        debugPrint('   (Test OTP: $_testOTP)');
      }

      // Try to send real OTP via Supabase
      try {
        await _supabase.auth.signInWithOtp(
          phone: fullNumber,
        );
        debugPrint('✅ OTP sent via Supabase');
      } catch (e) {
        // If SMS provider is not configured, that's OK for test mode
        debugPrint('⚠️ SMS provider not configured: $e');
        if (kDebugMode) {
          debugPrint('   Test OTP ($_testOTP) will still work');
        }
      }

      return {
        'success': true,
        'message': 'OTP sent successfully',
      };
    } catch (e) {
      debugPrint('Error sending OTP: $e');
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
    final fullNumber =
        phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

    // Check for test OTP first (bypasses real SMS verification)
    if (otp == _testOTP && kDebugMode) {
      debugPrint('🧪 TEST MODE: Using test OTP — routing through real Supabase OTP verification for the pinned test number');

      try {
        // Goes through the SAME real Supabase OTP flow as production mode,
        // just with the pre-configured test phone+code pair, so we get a
        // genuine, RLS-valid auth.uid() — not a locally-generated fake UUID
        // and not anonymous sign-in (which needs an Auth setting this
        // account doesn't have permission to enable).
        await _supabase.auth.signInWithOtp(phone: _testPhoneRaw);
        final response = await _supabase.auth.verifyOTP(
          type: OtpType.sms,
          phone: _testPhoneRaw,
          token: _testOTP,
        );

        if (response.user == null) {
          return {
            'success': false,
            'message': 'Test mode sign-in failed — no user returned.',
          };
        }

        final vendorId = response.user!.id;
        final existingVendor = await _supabase
            .from('vendors')
            .select()
            .eq('id', vendorId)
            .maybeSingle();

        final hasProfile = existingVendor != null;
        debugPrint('📊 Test-mode vendor check: ${hasProfile ? "exists" : "needs profile setup"} (id: $vendorId)');

        _testSession = {
          'vendorId': vendorId,
          'phone': fullNumber,
          'testMode': true,
        };

        return {
          'success': true,
          'message': 'Login successful (test mode)',
          'hasProfile': hasProfile,
          'vendorId': vendorId,
          'testMode': true,
        };
      } catch (e) {
        // Surfaced explicitly (rather than letting it propagate to the OTP
        // screen's generic "Verification failed" catch-all) so the actual
        // cause is visible.
        debugPrint('❌ Test mode sign-in error: $e');
        return {
          'success': false,
          'message': 'Test mode error: ${e.toString()}',
        };
      }
    }

    // PRODUCTION MODE: Real OTP verification via Supabase
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: fullNumber,
        token: otp,
      );

      if (response.user != null) {
        _testSession = null; // Clear test session if using real auth

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
          'vendorId': response.user!.id,
        };
      }

      return {
        'success': false,
        'message': 'Invalid OTP',
      };
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Verification failed. Please try again.',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _testSession = null; // Clear test session
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Get current user (Supabase or test session)
  User? get currentUser {
    // If we have a test session, return a mock user
    if (_testSession != null) {
      // Return null since we don't have a real User object
      // The vendor ID will be accessible via currentVendorId
      return null;
    }
    return _supabase.auth.currentUser;
  }

  /// Check if user is authenticated (Supabase OR test session)
  bool get isAuthenticated {
    return _supabase.auth.currentUser != null || _testSession != null;
  }

  /// Get current vendor ID (Supabase OR test session)
  String? get currentVendorId {
    // Priority 1: Supabase user
    final supabaseUserId = _supabase.auth.currentUser?.id;
    if (supabaseUserId != null) return supabaseUserId;

    // Priority 2: Test session (in-memory, NOT persisted)
    return _testSession?['vendorId'] as String?;
  }

  /// Check if currently in test mode
  bool get isInTestMode => _testSession != null;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
