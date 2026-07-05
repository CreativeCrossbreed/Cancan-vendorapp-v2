import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../config/supabase_config.dart';

/// Authentication Service — phone OTP via 2Factor.in.
///
/// Flow:
///   sendOTP   → POST /api/auth/send-otp   (backend calls 2Factor AUTOGEN)
///   verifyOTP → POST /api/auth/verify-otp (backend calls 2Factor VERIFY3, then
///               returns a deterministic Supabase password for this phone)
///               → app does signInWithPassword() to get a REAL Supabase session,
///                 so auth.uid()/RLS work exactly as before.
class AuthService {
  final _supabase = SupabaseConfig.client;

  /// Send OTP to phone number.
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phoneNumber}),
      );
      final body = _decode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        return {'success': true, 'message': body['message'] ?? 'OTP sent successfully'};
      }
      return {
        'success': false,
        'message': body['message'] ?? 'Failed to send OTP. Please try again.',
      };
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  /// Verify OTP, then establish a real Supabase session.
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phoneNumber, 'otp': otp}),
      );
      final body = _decode(response.body);

      if (response.statusCode != 200 || body['success'] != true) {
        return {
          'success': false,
          'message': body['message'] ?? 'Invalid or expired OTP.',
        };
      }

      // Establish the actual Supabase session with the returned credentials.
      final phone = body['phone'] as String;
      final password = body['password'] as String;
      final authResp = await _supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );

      if (authResp.user == null) {
        return {'success': false, 'message': 'Sign-in failed. Please try again.'};
      }

      return {
        'success': true,
        'message': 'Login successful',
        'hasProfile': body['hasProfile'] == true,
        'vendorId': authResp.user!.id,
        'user': authResp.user,
      };
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {'success': false, 'message': 'Verification failed. Please try again.'};
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : {};
    } catch (_) {
      return {};
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Get current vendor ID (== auth.uid())
  String? get currentVendorId => _supabase.auth.currentUser?.id;

  /// Retained for API compatibility with callers; always false now.
  bool get isInTestMode => false;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
