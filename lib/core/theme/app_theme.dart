import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lovepin/core/constants/app_colors.dart';
import 'package:lovepin/core/constants/app_fonts.dart';
import 'package:lovepin/core/constants/app_sizes.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.pinkDark,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.pink,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.lavenderDark,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.lavender,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.skyBlueDark,
        onTertiary: AppColors.white,
        tertiaryContainer: AppColors.skyBlue,
        onTertiaryContainer: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.white,
        outline: AppColors.border,
      ),
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppSizes.iconLg,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.nunito(
          fontSize: AppFonts.bodySmall,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: AppFonts.h3,
          fontWeight: AppFonts.semiBold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize: AppFonts.bodySize,
          color: AppColors.textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.border,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text Theme
  // ---------------------------------------------------------------------------

  static TextTheme get _textTheme {
    return TextTheme(
      // Display styles — using Caveat (handwriting) for emotional flair
      displayLarge: GoogleFonts.caveat(
        fontSize: 34,
        fontWeight: AppFonts.bold,
        color: AppColors.textPrimary,
        height: AppFonts.lineHeightTight,
      ),
      displayMedium: GoogleFonts.caveat(
        fontSize: 30,
        fontWeight: AppFonts.bold,
        color: AppColors.textPrimary,
        height: AppFonts.lineHeightTight,
      ),
      displaySmall: GoogleFonts.caveat(
        fontSize: 26,
        fontWeight: AppFonts.semiBold,
        color: AppColors.textPrimary,
        height: AppFonts.lineHeightTight,
      ),

      // Headline styles — Nunito
      headlineLarge: GoogleFonts.nunito(
        fontSize: AppFonts.h1,
        fontWeight: AppFonts.bold,
        color: AppColors.textPrimary,
        height: AppFonts.lineHeightTight,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: AppFonts.h2,
        fontWeight: AppFonts.bold,
        color: AppColors.textPrimary,
        height: AppFonts.lineHeightTight,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize: AppFonts.h3,
        fontWeight: AppFonts.semiBold,
        color: AppColors.textPrimary,
        height: AppFonts.lineHeightTight,
      ),

      // Title styles — Nunito
      titleLarge: GoogleFonts.nunito(
        fontSize: AppFonts.h3,
        fontWeight: AppFonts.semiBold,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: AppFonts.bodySize,
        fontWeight: AppFonts.semiBold,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.nunito(
        fontSize: AppFonts.bodySmall,
        fontWeight: AppFonts.semiBold,
        color: AppColors.textPrimary,
      ),

      // Body styles — Nunito
      bodyLarge: GoogleFonts.nunito(
        fontSize: AppFonts.bodySize,
        fontWeight: AppFonts.regular,
        color: AppColors.textPrimary,
        height: AppFonts.lineHeightNormal,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: AppFonts.bodySmall,
        fontWeight: AppFonts.regular,
        color: AppColors.textPrimary,
        height: AppFonts.lineHeightNormal,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: AppFonts.caption,
        fontWeight: AppFonts.regular,
        color: AppColors.textSecondary,
        height: AppFonts.lineHeightNormal,
      ),

      // Label styles — Nunito
      labelLarge: GoogleFonts.nunito(
        fontSize: AppFonts.bodySmall,
        fontWeight: AppFonts.semiBold,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.nunito(
        fontSize: AppFonts.caption,
        fontWeight: AppFonts.medium,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.nunito(
        fontSize: AppFonts.tiny,
        fontWeight: AppFonts.medium,
        color: AppColors.textSecondary,
        letterSpacing: AppFonts.letterSpacingWide,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar Theme
  // ---------------------------------------------------------------------------

  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: AppFonts.h3,
        fontWeight: AppFonts.semiBold,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AppSizes.iconLg,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card Theme
  // ---------------------------------------------------------------------------

  static CardTheme get _cardTheme {
    return CardTheme(
      color: AppColors.surface,
      elevation: AppSizes.cardElevation,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLg,
        vertical: AppSizes.paddingSm,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Elevated Button Theme
  // ---------------------------------------------------------------------------

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pinkDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        minimumSize: const Size(AppSizes.buttonMinWidth, AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXxl,
          vertical: AppSizes.paddingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize: AppFonts.bodySize,
          fontWeight: AppFonts.semiBold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Outlined Button Theme
  // ---------------------------------------------------------------------------

  static OutlinedButtonThemeData get _outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.pinkDark,
        elevation: 0,
        minimumSize: const Size(AppSizes.buttonMinWidth, AppSizes.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingXxl,
          vertical: AppSizes.paddingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        side: const BorderSide(color: AppColors.pinkDark, width: 1.5),
        textStyle: GoogleFonts.nunito(
          fontSize: AppFonts.bodySize,
          fontWeight: AppFonts.semiBold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Text Button Theme
  // ---------------------------------------------------------------------------

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.pinkDark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLg,
          vertical: AppSizes.paddingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        textStyle: GoogleFonts.nunito(
          fontSize: AppFonts.bodySmall,
          fontWeight: AppFonts.semiBold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input Decoration Theme
  // ---------------------------------------------------------------------------

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLg,
        vertical: AppSizes.paddingMd,
      ),
      hintStyle: GoogleFonts.nunito(
        fontSize: AppFonts.bodySize,
        fontWeight: AppFonts.regular,
        color: AppColors.textHint,
      ),
      labelStyle: GoogleFonts.nunito(
        fontSize: AppFonts.bodySmall,
        fontWeight: AppFonts.medium,
        color: AppColors.textSecondary,
      ),
      errorStyle: GoogleFonts.nunito(
        fontSize: AppFonts.caption,
        fontWeight: AppFonts.regular,
        color: AppColors.error,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        borderSide: const BorderSide(color: AppColors.pinkDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Navigation Bar Theme
  // ---------------------------------------------------------------------------

  static BottomNavigationBarThemeData get _bottomNavigationBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.pinkDark,
      unselectedItemColor: AppColors.textHint,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.nunito(
        fontSize: AppFonts.caption,
        fontWeight: AppFonts.semiBold,
      ),
      unselectedLabelStyle: GoogleFonts.nunito(
        fontSize: AppFonts.caption,
        fontWeight: AppFonts.regular,
      ),
      selectedIconTheme: const IconThemeData(
        size: AppSizes.bottomNavIconSize,
        color: AppColors.pinkDark,
      ),
      unselectedIconTheme: const IconThemeData(
        size: AppSizes.bottomNavIconSize,
        color: AppColors.textHint,
      ),
    );
  }
}
