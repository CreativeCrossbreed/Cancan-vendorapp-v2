import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// Notification Service - Handles push notifications and real-time updates
class NotificationService {
  final _supabase = SupabaseConfig.client;
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize push notifications
      await _initializePushNotifications();

      // Set up real-time listeners
      await _setupRealtimeListeners();

      AppLogger.i('Notification service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Error initializing notification service: $e', e, stackTrace);
    }
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      var query =
          _supabase.from('notifications').select('*').eq('vendor_id', vendorId);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final result =
          await query.order('created_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(result);
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching notification history: $e', e, stackTrace);
      return [];
    }
  }

  /// Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId) async {
    try {
      await _supabase.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);

      return {
        'success': true,
        'message': 'Notification marked as read',
      };
    } catch (e) {
      AppLogger.e('Error marking notification as read: $e');
      return {
        'success': false,
        'message': 'Failed to mark notification as read',
      };
    }
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('vendor_id', vendorId)
          .eq('is_read', false);

      return {
        'success': true,
        'message': 'All notifications marked as read',
      };
    } catch (e) {
      AppLogger.e('Error marking all notifications as read: $e');
      return {
        'success': false,
        'message': 'Failed to mark all notifications as read',
      };
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final result = await _supabase
          .from('notification_preferences')
          .select('*')
          .eq('vendor_id', vendorId)
          .single();

      return result ??
          {
            'vendor_id': vendorId,
            'new_order_notifications': true,
            'payment_notifications': true,
            'inventory_alerts': true,
            'customer_notifications': true,
            'promotional_notifications': false,
            'email_notifications': true,
            'push_notifications': true,
            'sms_notifications': false,
          };
    } catch (e) {
      AppLogger.e('Error fetching notification preferences: $e');
      return {};
    }
  }

  /// Update notification preferences
  Future<Map<String, dynamic>> updateNotificationPreferences(
      Map<String, dynamic> preferences) async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      await _supabase.from('notification_preferences').upsert({
        'vendor_id': vendorId,
        ...preferences,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return {
        'success': true,
        'message': 'Notification preferences updated',
      };
    } catch (e) {
      AppLogger.e('Error updating notification preferences: $e');
      return {
        'success': false,
        'message': 'Failed to update notification preferences',
      };
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final result = await _supabase
          .from('notifications')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('is_read', false);

      return result.length;
    } catch (e) {
      AppLogger.e('Error fetching unread notification count: $e');
      return 0;
    }
  }

  // Private methods

  Future<void> _initializePushNotifications() async {
    try {
      // This would integrate with Firebase Cloud Messaging or similar
      // For now, we'll simulate the initialization
      AppLogger.i('Push notifications initialized');
    } catch (e) {
      AppLogger.e('Error initializing push notifications: $e');
    }
  }

  Future<void> _setupRealtimeListeners() async {
    try {
      // Listen for new orders
      _supabase
          .channel('new_orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              _handleNewOrderNotification(payload.newRecord);
            },
          )
          .subscribe();

      // Listen for payment updates
      _supabase
          .channel('payment_updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'payments',
            callback: (payload) {
              _handlePaymentNotification(payload.newRecord);
            },
          )
          .subscribe();

      // Listen for inventory alerts
      _supabase
          .channel('inventory_alerts')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'vendor_products',
            callback: (payload) {
              _handleInventoryAlert(payload.newRecord);
            },
          )
          .subscribe();

      AppLogger.i('Real-time listeners set up successfully');
    } catch (e) {
      AppLogger.e('Error setting up real-time listeners: $e');
    }
  }

  void _handleNewOrderNotification(Map<String, dynamic> order) {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId != null && order['vendor_id'] == vendorId) {
        // Create notification for new order
        _createNotification({
          'vendor_id': vendorId,
          'type': 'new_order',
          'title': 'New Order Received',
          'message': 'Order #${order['id']} has been placed',
          'data': order,
        });
      }
    } catch (e) {
      AppLogger.e('Error handling new order notification: $e');
    }
  }

  void _handlePaymentNotification(Map<String, dynamic> payment) {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId != null && payment['vendor_id'] == vendorId) {
        // Create notification for payment update
        _createNotification({
          'vendor_id': vendorId,
          'type': 'payment',
          'title': 'Payment Update',
          'message': 'Payment status updated to ${payment['status']}',
          'data': payment,
        });
      }
    } catch (e) {
      AppLogger.e('Error handling payment notification: $e');
    }
  }

  void _handleInventoryAlert(Map<String, dynamic> product) {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId != null &&
          product['vendor_id'] == vendorId &&
          product['is_low_stock'] == true) {
        // Create notification for low stock alert
        _createNotification({
          'vendor_id': vendorId,
          'type': 'inventory_alert',
          'title': 'Low Stock Alert',
          'message': 'Product ${product['name']} is running low on stock',
          'data': product,
        });
      }
    } catch (e) {
      AppLogger.e('Error handling inventory alert: $e');
    }
  }

  Future<void> _createNotification(
      Map<String, dynamic> notificationData) async {
    try {
      await _supabase.from('notifications').insert({
        ...notificationData,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      AppLogger.i('Notification created: ${notificationData['title']}');
    } catch (e) {
      AppLogger.e('Error creating notification: $e');
    }
  }
}
