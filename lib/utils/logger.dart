import 'package:flutter/foundation.dart';

class Logger {
  static const String _prefix = '[Collo]';
  static bool _debugMode = kDebugMode;

  /// Active/désactive le mode debug
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }

  /// Log d'information
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_debugMode) {
      print('$_prefix ℹ️ INFO: $message');
      if (error != null) {
        print('$_prefix Error: $error');
      }
      if (stackTrace != null) {
        print('$_prefix StackTrace: $stackTrace');
      }
    }
  }

  /// Log de succès
  static void success(String message) {
    if (_debugMode) {
      print('$_prefix ✅ SUCCESS: $message');
    }
  }

  /// Log d'avertissement
  static void warning(String message, [dynamic error]) {
    if (_debugMode) {
      print('$_prefix ⚠️ WARNING: $message');
      if (error != null) {
        print('$_prefix Error: $error');
      }
    }
  }

  /// Log d'erreur
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_debugMode) {
      print('$_prefix ❌ ERROR: $message');
      if (error != null) {
        print('$_prefix Error: $error');
      }
      if (stackTrace != null) {
        print('$_prefix StackTrace: $stackTrace');
      }
    }
  }

  /// Log de débogage
  static void debug(String message, [dynamic data]) {
    if (_debugMode) {
      print('$_prefix 🐛 DEBUG: $message');
      if (data != null) {
        print('$_prefix Data: $data');
      }
    }
  }

  /// Log de performance
  static void performance(String operation, Duration duration) {
    if (_debugMode) {
      print('$_prefix ⏱️ PERFORMANCE: $operation took ${duration.inMilliseconds}ms');
    }
  }

  /// Log de navigation
  static void navigation(String from, String to) {
    if (_debugMode) {
      print('$_prefix 🗺️ NAVIGATION: $from → $to');
    }
  }

  /// Log de données
  static void data(String label, dynamic data) {
    if (_debugMode) {
      print('$_prefix 📊 DATA: $label');
      print('$_prefix $data');
    }
  }
}
