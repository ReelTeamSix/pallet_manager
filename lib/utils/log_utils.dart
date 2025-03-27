import 'package:flutter/foundation.dart';

/// Utility class for centralized logging
class LogUtils {
  /// Log a debug message only in debug mode
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('DEBUG: $message');
    }
  }

  /// Log an error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('ERROR: $message');
      if (error != null) {
        debugPrint('DETAILS: $error');
      }
      if (stackTrace != null) {
        debugPrint('STACK: $stackTrace');
      }
    }
  }

  /// Log an info message about a process or operation
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('INFO: $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('WARNING: $message');
    }
  }

  /// Log a message with a custom tag
  static void log(String tag, String message) {
    if (kDebugMode) {
      debugPrint('$tag: $message');
    }
  }
} 