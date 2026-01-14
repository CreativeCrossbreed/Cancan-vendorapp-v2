import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_service.dart';

/// Supabase configuration and initialization
///
/// This class uses compile-time constants for API keys via --dart-define.
/// Example usage:
/// ```bash
/// flutter run --dart-define-from-file=api-keys.json
/// flutter build apk --release --dart-define-from-file=api-keys.json --obfuscate
/// ```
class SupabaseConfig {
  /// Supabase URL from compile-time constants
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase Anon Key from compile-time constants
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static Future<void> initialize() async {
    // Validate credentials
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase credentials not configured.\n'
        'Please use --dart-define to pass SUPABASE_URL and SUPABASE_ANON_KEY.\n'
        'Example: flutter run --dart-define-from-file=api-keys.json',
      );
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
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
