import 'package:flutter/material.dart';
import 'logger.dart';
import '../config/theme.dart';

/// Centralized error handler for the app
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

  /// Get user-friendly error message from common error types
  static String getErrorMessage(Object error) {
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
}