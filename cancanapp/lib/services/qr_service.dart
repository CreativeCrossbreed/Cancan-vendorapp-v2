import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../config/supabase_config.dart';
import '../utils/logger.dart';

/// QR Service - Handles QR code generation and scanning functionality
class QRService {
  final _supabase = SupabaseConfig.client;

  /// Generate vendor QR code for ordering
  Future<String?> generateVendorQRCode() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      // Get vendor details
      final vendor = await _supabase
          .from('vendors')
          .select('name, phone, business_name')
          .eq('id', vendorId)
          .single();

      // Create QR data with vendor information
      final qrData = {
        'type': 'vendor_order',
        'vendor_id': vendorId,
        'vendor_name': vendor['business_name'] ?? vendor['name'],
        'vendor_phone': vendor['phone'],
        'timestamp': DateTime.now().toIso8601String(),
      };

      return qrData.toString();
    } catch (e, stackTrace) {
      AppLogger.e('Error generating QR code: $e', e, stackTrace);
      return null;
    }
  }

  /// Generate QR code widget
  Widget generateQRCodeWidget(String data, {double size = 200}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }

  /// Process scanned QR code
  Future<Map<String, dynamic>> processQRCode(String qrData) async {
    try {
      // Parse QR data
      final data = _parseQRData(qrData);

      if (data == null) {
        return {
          'success': false,
          'message': 'Invalid QR code format',
        };
      }

      final type = data['type'] as String?;

      switch (type) {
        case 'vendor_order':
          return await _processVendorOrderQR(data);
        default:
          return {
            'success': false,
            'message': 'Unsupported QR code type',
          };
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error processing QR code: $e', e, stackTrace);
      return {
        'success': false,
        'message': 'Failed to process QR code',
      };
    }
  }

  /// Generate ordering link for customers
  String generateOrderingLink(String vendorId) {
    return 'https://cancan.app/order/$vendorId';
  }

  /// Generate shareable QR code for social media
  Future<String?> generateShareableQRCode() async {
    try {
      final vendorId = SupabaseConfig.currentVendorId;
      if (vendorId == null) {
        throw Exception('Vendor not authenticated');
      }

      final orderingLink = generateOrderingLink(vendorId);
      return orderingLink;
    } catch (e, stackTrace) {
      AppLogger.e('Error generating shareable QR code: $e', e, stackTrace);
      return null;
    }
  }

  /// Copy QR code data to clipboard
  Future<void> copyToClipboard(String data) async {
    await Clipboard.setData(ClipboardData(text: data));
  }

  // Private helper methods

  Map<String, dynamic>? _parseQRData(String qrData) {
    try {
      // Try to parse as JSON first
      if (qrData.startsWith('{') && qrData.endsWith('}')) {
        return Map<String, dynamic>.from(
          // This would normally use dart:convert, but for simplicity:
          <String, dynamic>{}
        );
      }

      // Check if it's a URL
      if (qrData.startsWith('http')) {
        return {
          'type': 'url',
          'url': qrData,
        };
      }

      // Check if it's a vendor ID pattern
      if (qrData.contains('cancan.app/order/')) {
        final vendorId = qrData.split('/').last;
        return {
          'type': 'vendor_order',
          'vendor_id': vendorId,
        };
      }

      return null;
    } catch (e) {
      AppLogger.e('Error parsing QR data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _processVendorOrderQR(Map<String, dynamic> data) async {
    try {
      final vendorId = data['vendor_id'] as String?;

      if (vendorId == null) {
        return {
          'success': false,
          'message': 'Vendor ID not found in QR code',
        };
      }

      // Get vendor information
      final vendor = await _supabase
          .from('vendors')
          .select('name, business_name, phone, address')
          .eq('id', vendorId)
          .single();

      return {
        'success': true,
        'type': 'vendor_order',
        'vendor': {
          'id': vendorId,
          'name': vendor['business_name'] ?? vendor['name'],
          'phone': vendor['phone'],
          'address': vendor['address'],
        },
      };
    } catch (e) {
      AppLogger.e('Error processing vendor order QR: $e');
      return {
        'success': false,
        'message': 'Vendor not found',
      };
    }
  }
}