import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

/// App logger utility - replacement for print statements
class AppLogger {
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  /// For critical errors that should be visible in release builds too
  static void critical(String message, [Object? error, StackTrace? stackTrace]) {
    logger.e('CRITICAL: $message', error: error, stackTrace: stackTrace);
  }
}