import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PerformanceHelper {
  /// Cache for frequently accessed data
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Get cached data or compute and cache it
  static T? getCachedData<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null) {
      if (DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _cache[key] as T?;
      } else {
        // Cache expired
        _cache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
    return null;
  }

  /// Cache data with optional expiry
  static void cacheData<T>(String key, T data, {Duration? expiry}) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Clear specific cache key
  static void clearCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Clear all cache
  static void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Measure execution time of a function
  static Future<T> measureTime<T>(
    String operation,
    Future<T> Function() operationFunction,
  ) async {
    if (!kDebugMode) {
      return await operationFunction();
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await operationFunction();
      stopwatch.stop();
      debugPrint('⏱️ $operation took ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      debugPrint('❌ $operation failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  /// Check internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Debounce function calls
  static Timer? _debounceTimer;

  static void debounce(
    Duration delay,
    VoidCallback callback,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
}