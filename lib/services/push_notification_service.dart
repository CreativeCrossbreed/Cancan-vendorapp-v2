import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/supabase_config.dart';

/// Registers this device for FCM push notifications and keeps the
/// `device_tokens` table in sync with the vendor's current auth.uid().
/// Call [initialize] once after a vendor is authenticated (e.g. in
/// HomeScreen.initState or right after login).
class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: androidInit),
    );

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

    // Foreground messages: surface as a local notification since FCM
    // does not show a system notification while the app is foregrounded.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _local.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'orders_channel',
            'Orders',
            channelDescription: 'New order and delivery notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  static Future<void> _saveToken(String token) async {
    final vendorId = SupabaseConfig.currentVendorId;
    if (vendorId == null) return;

    try {
      await SupabaseConfig.client.from('device_tokens').upsert(
        {
          'vendor_id': vendorId,
          'token': token,
          'platform': 'android',
        },
        onConflict: 'token',
      );
    } catch (e) {
      // Non-fatal: push registration failing should never block app usage.
      debugPrint('⚠️ Failed to save device token: $e');
    }
  }

  /// Call on logout so the token isn't pushed to the next vendor on this device.
  static Future<void> clear() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await SupabaseConfig.client.from('device_tokens').delete().eq('token', token);
    } catch (_) {}
  }
}
