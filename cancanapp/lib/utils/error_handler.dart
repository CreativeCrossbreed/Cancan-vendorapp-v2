import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'logger.dart';
import '../config/theme.dart';
import '../config/app_config.dart';

/// Custom exception types for better error handling
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
    stackTrace: stackTrace,
  );
}

/// Centralized Error Handler
class ErrorHandler {
  /// Handle and show error to user
  static void handleError(
    BuildContext context,
    Object error, {
    String? title,
    VoidCallback? onRetry,
    bool showRetry = false,
  }) {
    AppLogger.e('UI Error: ${error.toString()}');

    String message = error.toString();

    // Clean up common error messages
    if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red[700],
        content: Text(message),
        action: showRetry && onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    AppLogger.i('Success: $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[700],
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// Show info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    AppLogger.i('Info: $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primaryBlue,
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// Handle async operations with error handling
  static Future<T?> handleAsyncOperation<T>({
    required Future<T> Function() operation,
    String? context,
    T? fallbackValue,
    bool showErrorDialog = false,
    BuildContext? buildContext,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      final exception = _parseException(e, stackTrace);
      _logError(exception, context);

      if (showErrorDialog && buildContext != null) {
        handleError(buildContext, exception);
      }

      return fallbackValue;
    }
  }

  /// Parse various exception types into our custom exceptions
  static AppException _parseException(dynamic error, StackTrace? stackTrace) {
    if (error is AppException) {
      return error;
    }

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection') ||
        error.toString().contains('Timeout') ||
        error.toString().contains('Network')) {
      return NetworkException(
        message: 'Network connection error. Please check your internet connection.',
        code: 'NETWORK_ERROR',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Auth errors
    if (error.toString().contains('401') ||
        error.toString().contains('Unauthorized') ||
        error.toString().contains('Authentication') ||
        error.toString().contains('Invalid session')) {
      return AuthException(
        message: 'Authentication failed. Please log in again.',
        code: 'AUTH_ERROR',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic error
    return AppException(
      message: 'An unexpected error occurred. Please try again.',
      code: 'UNKNOWN_ERROR',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error based on type and environment
  static void _logError(AppException exception, String? context) {
    final contextMessage = context != null ? '[$context] ' : '';

    switch (exception.runtimeType) {
      case NetworkException:
        AppLogger.w('${contextMessage}Network Error: ${exception.message}');
        break;
      case AuthException:
        AppLogger.w('${contextMessage}Auth Error: ${exception.message}');
        break;
      default:
        if (AppConfig.shouldEnableVerboseLogging) {
          AppLogger.e('${contextMessage}Error: ${exception.message}',
              exception.originalError, exception.stackTrace);
        } else {
          AppLogger.e('${contextMessage}Error: ${exception.message}');
        }
        break;
    }

    // In development mode, always log the full error
    if (AppConfig.isDevelopment && exception.originalError != null) {
      AppLogger.d('Original error: ${exception.originalError}',
          exception.originalError, exception.stackTrace);
    }
  }

  /// Get user-friendly error message from common error types
  static String getErrorMessage(Object error) {
    if (error is AppException) {
      return getUserFriendlyMessage(error);
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('permission')) {
      return 'You don\'t have permission to perform this action.';
    }

    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Please log in to continue.';
    }

    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  /// Get user-friendly message based on exception type
  static String getUserFriendlyMessage(AppException exception) {
    switch (exception.runtimeType) {
      case NetworkException:
        return 'No internet connection. Please check your network and try again.';
      case AuthException:
        return 'Your session has expired. Please log in again.';
      default:
        if (AppConfig.isDevelopment) {
          return exception.message;
        }
        return 'Something went wrong. Please try again.';
    }
  }
}