import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/session_service.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  static Future<void> initialize() async {
    // Load environment variables
    await dotenv.load(fileName: ".env");

    // Get credentials from .env file
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    // Validate credentials
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase credentials not found. Please check your .env file.',
      );
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // More secure
      ),
    );
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
