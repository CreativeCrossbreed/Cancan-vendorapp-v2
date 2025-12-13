import 'package:shared_preferences/shared_preferences.dart';

/// Session Service - Persists lightweight vendor session info using SharedPreferences.
///
/// This is intentionally simple: we just remember whether a vendor is "logged in"
/// for this device and what their vendorId / phone are, so we can:
/// - Skip the login screen on next app launch
/// - Use the stored vendorId in Supabase queries when not using real auth
class SessionService {
  static const _keyVendorId = 'session_vendor_id';
  static const _keyVendorPhone = 'session_vendor_phone';
  static const _keyHasProfile = 'session_has_profile';

  static SharedPreferences? _prefs;

  static String? _vendorId;
  static String? _vendorPhone;
  static bool _hasProfile = false;

  /// Must be called once during app startup before using getters.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _vendorId = _prefs!.getString(_keyVendorId);
    _vendorPhone = _prefs!.getString(_keyVendorPhone);
    _hasProfile = _prefs!.getBool(_keyHasProfile) ?? false;
  }

  /// Whether we have a stored session on this device.
  static bool get hasSession => _vendorId != null;

  static String? get vendorId => _vendorId;

  static String? get vendorPhone => _vendorPhone;

  static bool get hasProfile => _hasProfile;

  /// Save / update the current vendor session.
  static Future<void> saveSession({
    required String vendorId,
    String? vendorPhone,
    required bool hasProfile,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();

    _vendorId = vendorId;
    _vendorPhone = vendorPhone;
    _hasProfile = hasProfile;

    await _prefs!.setString(_keyVendorId, vendorId);
    if (vendorPhone != null) {
      await _prefs!.setString(_keyVendorPhone, vendorPhone);
    } else {
      await _prefs!.remove(_keyVendorPhone);
    }
    await _prefs!.setBool(_keyHasProfile, hasProfile);
  }

  /// Clear the stored vendor session (used on logout).
  static Future<void> clearSession() async {
    _prefs ??= await SharedPreferences.getInstance();

    _vendorId = null;
    _vendorPhone = null;
    _hasProfile = false;

    await _prefs!.remove(_keyVendorId);
    await _prefs!.remove(_keyVendorPhone);
    await _prefs!.remove(_keyHasProfile);
  }
}


