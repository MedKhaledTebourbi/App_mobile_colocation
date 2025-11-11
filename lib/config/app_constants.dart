import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Collo';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color accentColor = Colors.orange;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration notificationDuration = Duration(seconds: 5);
  static const Duration loadingTimeout = Duration(seconds: 30);

  // Sizes
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;

  // API
  static const String baseUrl = 'https://api.example.com';
  static const int connectionTimeout = 30;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // Messages
  static const String loadingMessage = 'Chargement...';
  static const String errorMessage = 'Une erreur est survenue';
  static const String noDataMessage = 'Aucune donnée disponible';
  static const String successMessage = 'Opération réussie';
  static const String confirmMessage = 'Êtes-vous sûr ?';

  // Regex Patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^[0-9]{10,}$';
}
