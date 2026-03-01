import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary pastels
  static const Color pink = Color(0xFFFFD6E0);
  static const Color pinkDark = Color(0xFFFF8FAB);
  static const Color lavender = Color(0xFFE8D5F5);
  static const Color lavenderDark = Color(0xFFC9A2E2);
  static const Color cream = Color(0xFFFFF8F0);
  static const Color skyBlue = Color(0xFFD6EEFF);
  static const Color skyBlueDark = Color(0xFF9DD1F5);
  static const Color mint = Color(0xFFD4F0E7);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFFF8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color border = Color(0xFFF0E8E5);
  static const Color divider = Color(0xFFF5F0ED);
  static const Color error = Color(0xFFE57373);
  static const Color shadow = Color(0x1A000000);

  // Gradients
  static const LinearGradient pinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD6E0), Color(0xFFFFF0F3)],
  );

  static const LinearGradient lavenderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8D5F5), Color(0xFFF5EEFA)],
  );

  static const LinearGradient creamGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8F0), Color(0xFFFFFFFF)],
  );
}
