import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

/// Vendor Data Service - Caches vendor profile to reduce API calls
/// Loads data once on app launch and caches it locally
class VendorDataService {
  static const String _vendorDataKey = 'cached_vendor_data';
  static const String _lastFetchKey = 'vendor_data_last_fetch';

  static Map<String, dynamic>? _cachedVendorData;
  static DateTime? _lastFetchTime;
  static const _cacheValidityDuration = Duration(hours: 1); // Cache for 1 hour

  /// Get cached vendor data (returns immediately if available)
  static Map<String, dynamic>? get cachedVendorData => _cachedVendorData;

  /// Check if cache is valid
  static bool get isCacheValid {
    if (_cachedVendorData == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration;
  }

  /// Load vendor profile with caching
  /// - Returns cached data if available and valid
  /// - Otherwise fetches from Supabase
  /// - forceRefresh: bypass cache and fetch fresh data
  static Future<Map<String, dynamic>?> getVendorProfile({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && isCacheValid) {
      print('📦 Using cached vendor data');
      return _cachedVendorData;
    }

    // Try to load from SharedPreferences first
    if (!forceRefresh) {
      final cached = await _loadFromPrefs();
      if (cached != null) {
        _cachedVendorData = cached;
        print('📦 Loaded vendor data from local cache');
        return cached;
      }
    }

    // Fetch from Supabase
    print('🌐 Fetching vendor data from Supabase...');
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        print('⚠️ No vendor ID found');
        return null;
      }

      final data = await SupabaseConfig.client
          .from('vendors')
          .select()
          .eq('id', vendorId)
          .maybeSingle();

      if (data != null) {
        _cachedVendorData = data;
        _lastFetchTime = DateTime.now();
        await _saveToPrefs(data);
        print('✅ Vendor data cached: ${data['name']}');
      }

      return data;
    } catch (e) {
      print('❌ Error fetching vendor profile: $e');
      // Return cached data even if expired, as fallback
      return _cachedVendorData;
    }
  }

  /// Save vendor data to SharedPreferences
  static Future<void> _saveToPrefs(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_vendorDataKey, jsonEncode(data));
      await prefs.setString(_lastFetchKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ Error saving vendor data to prefs: $e');
    }
  }

  /// Load vendor data from SharedPreferences
  static Future<Map<String, dynamic>?> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_vendorDataKey);
      final lastFetchStr = prefs.getString(_lastFetchKey);

      if (dataStr != null && lastFetchStr != null) {
        final lastFetch = DateTime.parse(lastFetchStr);
        final age = DateTime.now().difference(lastFetch);

        // Check if cache is still valid
        if (age < _cacheValidityDuration) {
          final data = jsonDecode(dataStr) as Map<String, dynamic>;
          _lastFetchTime = lastFetch;
          return data;
        }
      }
    } catch (e) {
      print('❌ Error loading vendor data from prefs: $e');
    }
    return null;
  }

  /// Clear cached data (call after updates)
  static Future<void> clearCache() async {
    _cachedVendorData = null;
    _lastFetchTime = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vendorDataKey);
      await prefs.remove(_lastFetchKey);
      print('🗑️ Vendor data cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Update cached data (call after profile updates)
  static Future<void> updateCache(Map<String, dynamic> newData) async {
    _cachedVendorData = newData;
    _lastFetchTime = DateTime.now();
    await _saveToPrefs(newData);
    print('✅ Vendor data cache updated');
  }

  /// Initialize - Load vendor data on app launch
  /// Call this in main.dart after Supabase initialization
  static Future<void> initialize() async {
    print('🚀 Initializing VendorDataService...');
    await getVendorProfile(forceRefresh: false);
  }
}
