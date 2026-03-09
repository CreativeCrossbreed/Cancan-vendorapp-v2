import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Service for fetching app-level settings from Supabase.
///
/// Reads from the `app_config` table and caches values locally
/// so they're available offline.
class AppSettingsService {
  static const String _cachePrefix = 'app_setting_';
  static SharedPreferences? _prefs;

  /// Cached in-memory values for the current session.
  static final Map<String, String> _cache = {};

  static Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Fetch a single setting by key from Supabase, with local cache fallback.
  static Future<String> get(String key, {String defaultValue = ''}) async {
    // 1. In-memory cache (fastest)
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    await _ensurePrefs();

    // 2. Try Supabase
    try {
      final response = await SupabaseConfig.client
          .from('app_config')
          .select('value')
          .eq('key', key)
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final value = response['value'] as String;
        _cache[key] = value;
        await _prefs?.setString('$_cachePrefix$key', value);
        return value;
      }
    } catch (e) {
      AppLogger.w('Failed to fetch setting "$key" from Supabase: $e');
    }

    // 3. Fallback to SharedPreferences cache
    final cached = _prefs?.getString('$_cachePrefix$key');
    if (cached != null && cached.isNotEmpty) {
      _cache[key] = cached;
      return cached;
    }

    return defaultValue;
  }

  /// Get the central WhatsApp Business number.
  ///
  /// This is the number ALL vendor QR codes point to.
  /// A webhook on the WhatsApp side parses `ref-<vendorId>` to identify vendors.
  static Future<String> getWhatsAppBusinessNumber() async {
    return get('whatsapp_business_number');
  }

  /// Get support email.
  static Future<String> getSupportEmail() async {
    return get('support_email', defaultValue: 'support@cancanindia.com');
  }

  /// Preload commonly used settings into memory cache.
  static Future<void> preload() async {
    await _ensurePrefs();
    try {
      final response =
          await SupabaseConfig.client.from('app_config').select('key, value');

      for (final row in response as List) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        _cache[key] = value;
        await _prefs?.setString('$_cachePrefix$key', value);
      }
      AppLogger.i('Preloaded ${_cache.length} app settings');
    } catch (e) {
      AppLogger.w('Failed to preload app settings: $e');
    }
  }

  /// Clear all cached settings.
  static void clearCache() {
    _cache.clear();
  }
}
