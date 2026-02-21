import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

class SecurityHelper {
  /// Sanitize user input
  static String sanitizeInput(String input) {
    // Remove potentially harmful characters
    return input
        .replaceAll(RegExp(r'[<>&\'"]'), '')
        .trim();
  }

  /// Validate phone number (Indian format)
  static bool isValidPhoneNumber(String phone) {
    // Remove any non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    // Check if it's 10 digits (without country code) or 12 digits (with 91)
    if (digitsOnly.length == 10) {
      return RegExp(r'^[6-9]\d{9}$').hasMatch(digitsOnly);
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return RegExp(r'^91[6-9]\d{9}$').hasMatch(digitsOnly);
    }

    return false;
  }

  /// Mask sensitive data for logging
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    return data.substring(0, visibleChars) + '*' * (data.length - visibleChars);
  }

  /// Generate secure random string
  static String generateSecureRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if string contains SQL injection patterns
  static bool containsSqlInjection(String input) {
    final sqlPatterns = [
      r'(?i)\b(union|select|insert|update|delete|drop|alter|create|exec)\b',
      r'(?i)(--|;|\/\*|\*\/|xp_|sp_)',
      r'(?i)(or\s+1\s*=\s*1|and\s+1\s*=\s*1)',
      r'(?i)(\'\s*;\s*drop|\'\s*;\s*delete)',
    ];

    for (final pattern in sqlPatterns) {
      if (RegExp(pattern).hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  /// Sanitize text to prevent script injection
  static String sanitizeText(String text) {
    return text
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '')
        .replaceAll('javascript:', '');
  }

  /// Copy to clipboard securely
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    // Clear from clipboard after 30 seconds for security
    Timer(const Duration(seconds: 30), () async {
      await Clipboard.setData(const ClipboardData(text: ''));
    });
  }
}