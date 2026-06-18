import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Authentication Service - Handles phone OTP authentication via Supabase
/// Test OTP (000000) supported for development without SMS costs
class AuthService {
  final _supabase = SupabaseConfig.client;

  // Test OTP for development - bypasses real SMS verification
  static const String _testOTP = '000000';

  // In-memory test session (NOT persisted - lost on app restart)
  static Map<String, dynamic>? _testSession;

  /// Generate a test UUID for development
  String _generateTestUUID(String phoneNumber) {
    final random = Random.secure();
    final hexDigits = '0123456789abcdef';
    final phoneHash = phoneNumber.hashCode.abs().toRadixString(16).padLeft(8, '0').substring(0, 8);

    final part1 = phoneHash;
    final part2 = List.generate(4, (_) => hexDigits[random.nextInt(16)]).join();
    final part3 = '4${List.generate(3, (_) => hexDigits[random.nextInt(16)]).join()}';
    final part4 = '${hexDigits[8 + random.nextInt(4)]}${List.generate(3, (_) => hexDigits[random.nextInt(16)]).join()}';
    final part5 = List.generate(12, (_) => hexDigits[random.nextInt(16)]).join();

    return '$part1-$part2-$part3-$part4-$part5';
  }

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {
    try {
      final fullNumber =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      print('📱 Sending OTP to $fullNumber...');
      if (kDebugMode) {
        print('   (Test OTP: $_testOTP)');
      }

      // Try to send real OTP via Supabase
      try {
        await _supabase.auth.signInWithOtp(
          phone: fullNumber,
        );
        print('✅ OTP sent via Supabase');
      } catch (e) {
        // If SMS provider is not configured, that's OK for test mode
        print('⚠️ SMS provider not configured: $e');
        if (kDebugMode) {
          print('   Test OTP ($_testOTP) will still work');
        }
      }

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
    final fullNumber =
        phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

    // Check for test OTP first (bypasses real SMS verification)
    if (otp == _testOTP && kDebugMode) {
      print('🧪 TEST MODE: Using test OTP for $fullNumber');

      // Create in-memory test session (LOST on app restart - NO auto-login)
      final testVendorId = _generateTestUUID(fullNumber);
      _testSession = {
        'vendorId': testVendorId,
        'phone': fullNumber,
        'testMode': true,
      };

      print('✅ Test mode session created: $testVendorId');
      print('⚠️ Session is IN-MEMORY only - will be lost on app restart');

      // Check if vendor profile exists in database for this phone number
      final existingVendor = await _supabase
          .from('vendors')
          .select()
          .eq('phone', fullNumber)
          .maybeSingle();

      final hasProfile = existingVendor != null;
      print('📊 Database check for phone $fullNumber: ${hasProfile ? "Vendor EXISTS" : "Vendor NOT found"}');

      if (hasProfile) {
        print('📋 Existing vendor ID: ${existingVendor['id']}');
        print('📋 Existing vendor name: ${existingVendor['name']}');
        print('📋 Using existing vendor ID instead of test UUID');
        // Update test session with real vendor ID
        _testSession!['vendorId'] = existingVendor['id'];
      }

      return {
        'success': true,
        'message': 'Login successful (test mode)',
        'hasProfile': hasProfile,
        'vendorId': _testSession!['vendorId'] as String,
        'testMode': true,
      };
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
      print('Error verifying OTP: $e');
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
      print('Error signing out: $e');
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
