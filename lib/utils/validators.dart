import 'package:collo/config/app_constants.dart';

class Validators {
  /// Valide une adresse email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(AppConstants.emailPattern);
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide';
    }
    return null;
  }

  /// Valide un mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caractères';
    }
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Le mot de passe ne doit pas dépasser ${AppConstants.maxPasswordLength} caractères';
    }
    return null;
  }

  /// Valide un nom d'utilisateur
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }
    if (value.length < AppConstants.minUsernameLength) {
      return 'Le nom d\'utilisateur doit contenir au moins ${AppConstants.minUsernameLength} caractères';
    }
    if (value.length > AppConstants.maxUsernameLength) {
      return 'Le nom d\'utilisateur ne doit pas dépasser ${AppConstants.maxUsernameLength} caractères';
    }
    return null;
  }

  /// Valide un numéro de téléphone
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    final phoneRegex = RegExp(AppConstants.phonePattern);
    if (!phoneRegex.hasMatch(value)) {
      return 'Veuillez entrer un numéro de téléphone valide';
    }
    return null;
  }

  /// Valide un champ requis
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valide un prix
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le prix est requis';
    }
    try {
      final price = double.parse(value);
      if (price <= 0) {
        return 'Le prix doit être supérieur à 0';
      }
      return null;
    } catch (e) {
      return 'Veuillez entrer un prix valide';
    }
  }

  /// Valide un nombre
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    try {
      final number = int.parse(value);
      if (number < 0) {
        return '$fieldName ne peut pas être négatif';
      }
      return null;
    } catch (e) {
      return 'Veuillez entrer un nombre valide pour $fieldName';
    }
  }

  /// Valide une URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'URL est requise';
    }
    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'Veuillez entrer une URL valide';
    }
  }

  /// Valide une date
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'La date est requise';
    }
    if (date.isBefore(DateTime.now())) {
      return 'La date ne peut pas être dans le passé';
    }
    return null;
  }

  /// Valide une plage de dates
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Les deux dates sont requises';
    }
    if (startDate.isAfter(endDate)) {
      return 'La date de début doit être avant la date de fin';
    }
    if (startDate.isAtSameMomentAs(endDate)) {
      return 'Les dates ne peuvent pas être identiques';
    }
    return null;
  }

  /// Valide une longueur de texte
  static String? validateLength(String? value, int minLength, int maxLength) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est requis';
    }
    if (value.length < minLength) {
      return 'Le texte doit contenir au moins $minLength caractères';
    }
    if (value.length > maxLength) {
      return 'Le texte ne doit pas dépasser $maxLength caractères';
    }
    return null;
  }
}
