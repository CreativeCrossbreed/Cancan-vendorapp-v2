import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'session_service.dart';

/// Authentication Service - Handles phone OTP authentication
/// Supports test OTP (000000) for development without SMS costs
class AuthService {
  final _supabase = SupabaseConfig.client;

  // Test OTP for development - bypasses real SMS verification when entered
  static const String _testOTP = '000000';

  /// Generate a test UUID for development
  String _generateTestUUID(String phoneNumber) {
    // Generate a UUID v4-like format for testing
    final random = Random.secure();
    final hexDigits = '0123456789abcdef';
    final phoneHash = phoneNumber.hashCode.abs().toRadixString(16).padLeft(8, '0').substring(0, 8);
    
    // Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx (UUID v4 format)
    final part1 = phoneHash;
    final part2 = List.generate(4, (_) => hexDigits[random.nextInt(16)]).join();
    final part3 = '4${List.generate(3, (_) => hexDigits[random.nextInt(16)]).join()}';
    final part4 = '${hexDigits[8 + random.nextInt(4)]}${List.generate(3, (_) => hexDigits[random.nextInt(16)]).join()}';
    final part5 = List.generate(12, (_) => hexDigits[random.nextInt(16)]).join();
    
    return '$part1-$part2-$part3-$part4-$part5';
  }

  /// Check if currently in test mode (based on session)
  bool get isInTestMode {
    return SessionService.vendorId != null && 
           SessionService.vendorId?.startsWith('test_vendor_') == true;
  }

  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOTP({required String phoneNumber}) async {
    // For development without SMS provider, simulate successful OTP send
    // In production with real SMS provider, this would call Supabase auth
    try {
      final fullNumber =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      print('📱 Sending OTP to +91$phoneNumber (simulated - no SMS provider needed)');

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'OTP sent successfully',
        'simulated': true,
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
    // Check for test OTP first (bypasses real SMS)
    if (otp == _testOTP) {
      // TEST MODE: Accept test OTP and create mock session
      print('🧪 TEST MODE: Using test OTP for +91$phoneNumber');

      await Future.delayed(
          const Duration(seconds: 1)); // Simulate network delay

      // Generate a proper UUID for test vendor ID
      final testVendorId = _generateTestUUID(phoneNumber);
      print('🧪 TEST MODE: Generated test vendor ID: $testVendorId');

      final fullNumber =
          phoneNumber.startsWith('+91') ? phoneNumber : '+91$phoneNumber';

      // TEST MODE: Skip Supabase auth, just save to session
      // The vendor will be created in the database when they complete profile setup
      await SessionService.saveSession(
        vendorId: testVendorId,
        vendorPhone: fullNumber,
        hasProfile: false,
      );

      return {
        'success': true,
        'message': 'Login successful',
        'hasProfile': false,
        'testMode': true,
        'vendorId': testVendorId,
      };
    }

    // PRODUCTION MODE: Real OTP verification via Supabase
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

        // Save session for production mode
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
      await SessionService.clearSession();
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Get current user
  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    return currentUser != null || SessionService.hasSession;
  }

  /// Get current vendor ID
  String? get currentVendorId {
    final userId = currentUser?.id;
    if (userId != null) return userId;
    return SessionService.vendorId;
  }

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
