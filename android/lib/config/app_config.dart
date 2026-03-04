import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// Application Configuration Service
///
/// All values come from compile-time constants via `--dart-define`.
/// Usage:
///   flutter run --dart-define-from-file=api-keys.json
///   flutter build apk --release --dart-define-from-file=api-keys.json
class AppConfig {
  // ── Core (required) ───────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // ── Environment ───────────────────────────────────────────────
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // ── Dev flags (only meaningful in debug builds) ───────────────
  static const bool _devModeEnv =
      bool.fromEnvironment('DEV_MODE', defaultValue: false);
  static const bool _debugModeEnv =
      bool.fromEnvironment('DEBUG_MODE', defaultValue: false);

  /// True only in debug builds AND when the env flag is set.
  static bool get devMode => kDebugMode && _devModeEnv;
  static bool get debugMode => kDebugMode && _debugModeEnv;

  // ── API config ────────────────────────────────────────────────
  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30000,
  );

  // ── Feature Flags ─────────────────────────────────────────────
  static const bool isPushNotificationsEnabled =
      bool.fromEnvironment('ENABLE_PUSH_NOTIFICATIONS', defaultValue: false);
  static const bool isAnalyticsEnabled =
      bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);
  static const bool isCrashReportingEnabled =
      bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: false);

  // ── External Service Keys (optional, compile-time) ────────────
  static const String fcmServerKey = String.fromEnvironment('FCM_SERVER_KEY');
  static const String razorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
  static const String razorpayKeySecret =
      String.fromEnvironment('RAZORPAY_KEY_SECRET');
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  // ── WhatsApp ──────────────────────────────────────────────────
  // The WhatsApp Business number is fetched from Supabase at runtime
  // via AppSettingsService — NOT stored here.
  // This keeps it updatable without redeploying the app.

  // ── Validation ────────────────────────────────────────────────
  static bool get isValidConfig {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      AppLogger.e(
        'Invalid config: SUPABASE_URL or SUPABASE_ANON_KEY is empty.\n'
        'Use --dart-define-from-file=api-keys.json',
      );
      return false;
    }
    return true;
  }

  // ── Logging helpers ───────────────────────────────────────────
  static bool get shouldEnableVerboseLogging => kDebugMode;
  static bool get shouldEnableAnalyticsLogging =>
      isAnalyticsEnabled && !isDevelopment;

  static String get apiBaseUrl => supabaseUrl;

  // ── Debug info (safe — gated by kDebugMode in logger) ─────────
  static Map<String, dynamic> get debugInfo => {
        'environment': environment,
        'devMode': devMode,
        'debugMode': debugMode,
        'apiTimeout': apiTimeout,
        'pushNotificationsEnabled': isPushNotificationsEnabled,
        'analyticsEnabled': isAnalyticsEnabled,
        'crashReportingEnabled': isCrashReportingEnabled,
        'validConfig': isValidConfig,
      };
}
