import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryNavy = Color(0xFF0B1F3A);
  static const Color primaryNavyLight = Color(0xFF1A3A5C);
  static const Color primaryNavyDark = Color(0xFF061325);

  // Backwards-compatible aliases (all screens use primaryGreen)
  static const Color primaryGreen = primaryNavy;
  static const Color primaryGreenLight = primaryNavyLight;
  static const Color primaryGreenDark = primaryNavyDark;

  static const Color secondaryGold = Color(0xFFC8A96B);
  static const Color secondaryGoldLight = Color(0xFFD9C094);
  static const Color secondaryGoldDark = Color(0xFFA68A4F);

  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  static const Color divider = Color(0xFFE0E0E0);
  static const Color cardShadow = Color(0x1A000000);

  static const Color statusInProgress = Color(0xFFFFA726);
  static const Color statusMatched = Color(0xFF66BB6A);
  static const Color statusRejected = Color(0xFFEF5350);

  static const Color centerMarker = Color(0xFF1976D2);
  static const Color depositMarker = Color(0xFF388E3C);
}
