import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 9 || cleaned.length > 15) {
      return 'Please enter a valid mobile number';
    }
    if (!RegExp(r'^[+]?[0-9]+$').hasMatch(cleaned)) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  static String? validateSaudiMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-]'), '');
    // Accept: +966XXXXXXXXX (12 chars with +) or 966XXXXXXXXX (12 digits) or 05XXXXXXXX (10 digits)
    if (RegExp(r'^\+9665[0-9]{8}$').hasMatch(cleaned)) return null;
    if (RegExp(r'^9665[0-9]{8}$').hasMatch(cleaned)) return null;
    if (RegExp(r'^05[0-9]{8}$').hasMatch(cleaned)) return null;
    return 'يرجى إدخال رقم جوال سعودي صحيح (مثال: +966512345678 أو 0512345678)';
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
        .hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  static bool isValidPassword(String password) {
    return RegExp(AppConstants.passwordPattern).hasMatch(password);
  }
}
