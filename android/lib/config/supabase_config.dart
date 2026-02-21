import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';
import '../services/session_service.dart';
import '../utils/logger.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      // Get credentials from AppConfig
      final supabaseUrl = AppConfig.supabaseUrl;
      final supabaseAnonKey = AppConfig.supabaseAnonKey;

      AppLogger.i('Initializing Supabase with URL: ${supabaseUrl.substring(0, 20)}...');

      // Initialize Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // More secure
        ),
      );

      AppLogger.i('Supabase initialized successfully');
    } catch (e) {
      AppLogger.e('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get current user from Supabase auth (used in production mode).
  static User? get currentUser => client.auth.currentUser;

  /// Get current vendor ID.
  ///
  /// Priority:
  /// 1. Authenticated Supabase user (production)
  /// 2. Locally stored vendor session (SharedPreferences)
  static String? get currentVendorId {
    final userId = currentUser?.id;
    if (userId != null) return userId;
    return SessionService.vendorId;
  }

  /// Check if user is authenticated / has an active session.
  static bool get isAuthenticated =>
      currentUser != null || SessionService.hasSession;
}
