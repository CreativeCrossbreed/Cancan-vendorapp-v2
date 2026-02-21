import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// Application Configuration Service
class AppConfig {
  static bool _initialized = false;

  /// Initialize the app configuration
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: ".env");
      _initialized = true;
      AppLogger.i('App configuration loaded successfully');
    } catch (e) {
      AppLogger.e('Failed to load .env file: $e');
      // Still mark as initialized to prevent repeated attempts
      _initialized = true;
    }
  }

  // Supabase Configuration
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    if (url.isEmpty) {
      throw Exception('SUPABASE_URL not found in environment variables');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    if (key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in environment variables');
    }
    return key;
  }

  // Environment
  static String get environment => dotenv.env['ENV'] ?? 'development';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // Development Mode
  static bool get devMode => dotenv.env['DEV_MODE'] == 'true';
  static bool get debugMode => dotenv.env['DEBUG_MODE'] == 'true';

  // API Configuration
  static int get apiTimeout {
    final timeout = dotenv.env['API_TIMEOUT'] ?? '30000';
    return int.tryParse(timeout) ?? 30000;
  }

  // Feature Flags
  static bool get isPushNotificationsEnabled => dotenv.env['ENABLE_PUSH_NOTIFICATIONS'] == 'true';
  static bool get isAnalyticsEnabled => dotenv.env['ENABLE_ANALYTICS'] == 'true';
  static bool get isCrashReportingEnabled => dotenv.env['ENABLE_CRASH_REPORTING'] == 'true';

  // External Service Keys (Optional)
  static String? get fcmServerKey => dotenv.env['FCM_SERVER_KEY'];
  static String? get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'];
  static String? get razorpayKeySecret => dotenv.env['RAZORPAY_KEY_SECRET'];
  static String? get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'];
  static String? get whatsappApiKey => dotenv.env['WHATSAPP_API_KEY'];
  static String? get whatsappPhoneNumberId => dotenv.env['WHATSAPP_PHONE_NUMBER_ID'];

  // Validation
  static bool get isValidConfig {
    try {
      // Check required fields
      supabaseUrl;
      supabaseAnonKey;
      return true;
    } catch (e) {
      AppLogger.e('Invalid configuration: $e');
      return false;
    }
  }

  // Logging configuration based on environment
  static bool get shouldEnableVerboseLogging => debugMode || isDevelopment;
  static bool get shouldEnableAnalyticsLogging => isAnalyticsEnabled && !isDevelopment;

  // API URLs for different environments
  static String get apiBaseUrl {
    switch (environment) {
      case 'production':
        return supabaseUrl;
      case 'staging':
        return supabaseUrl;
      default:
        return supabaseUrl;
    }
  }

  // Debug information
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