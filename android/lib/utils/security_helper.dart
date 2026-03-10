import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

/// Security utilities for input validation and sanitization.
class SecurityHelper {
  /// Sanitize user input — remove potentially harmful characters.
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp('[<>&]'), '')
        .replaceAll("'", '')
        .replaceAll('"', '')
        .trim();
  }

  /// Validate phone number (Indian format).
  static bool isValidPhoneNumber(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length == 10) {
      return RegExp(r'^[6-9]\d{9}$').hasMatch(digitsOnly);
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return RegExp(r'^91[6-9]\d{9}$').hasMatch(digitsOnly);
    }

    return false;
  }

  /// Mask sensitive data for logging.
  static String maskSensitiveData(String data, {int visibleChars = 4}) {
    if (data.length <= visibleChars) {
      return '*' * data.length;
    }
    return data.substring(0, visibleChars) + '*' * (data.length - visibleChars);
  }

  /// Generate secure random string.
  static String generateSecureRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Validate email format.
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }

  /// Check if string contains SQL injection patterns.
  static bool containsSqlInjection(String input) {
    final sqlPatterns = [
      RegExp(r'\b(union|select|insert|update|delete|drop|alter|create|exec)\b',
          caseSensitive: false),
      RegExp(r'(--|;|\/\*|\*\/|xp_|sp_)', caseSensitive: false),
      RegExp(r'(or\s+1\s*=\s*1|and\s+1\s*=\s*1)', caseSensitive: false),
    ];

    for (final pattern in sqlPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  /// Sanitize text to prevent script injection.
  static String sanitizeText(String text) {
    return text
        .replaceAll(
            RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '')
        .replaceAll('javascript:', '');
  }

  /// Copy to clipboard securely (clears after 30s).
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Timer(const Duration(seconds: 30), () async {
      await Clipboard.setData(const ClipboardData(text: ''));
    });
  }
}
