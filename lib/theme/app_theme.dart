import 'package:flutter/material.dart';

class AppColors {
  // Medical Precision Dark/Slate Palette
  static const Color primaryBackground = Color(0xFF090D16);
  static const Color secondaryBackground = Color(0xFF101726);
  static const Color primarySurface = Color(0xFF141D30);
  static const Color secondarySurface = Color(0xFF1C2842);
  static const Color darkSurface = Color(0xFF0F1728);
  static const Color cardBorder = Color(0xFF22314E);
  static const Color border = Color(0xFF22314E);

  // High-Contrast Medical Typography
  static const Color primaryText = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFF94A3B8);
  static const Color mutedText = Color(0xFF64748B);

  // Precision Research Accents
  static const Color primaryAccent = Color(0xFF3B82F6);
  static const Color secondaryBlue = Color(0xFF60A5FA);
  static const Color softBlue = Color(0xFF1E2B45);

  // Telemetry & Diagnostic Indicators
  static const Color success = Color(0xFF10B981);
  static const Color telemetryActive = Color(0xFF10B981);
  static const Color waveformCyan = Color(0xFF06B6D4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

class AppRadius {
  static const double chip = 8.0;
  static const double button = 12.0;
  static const double card = 16.0;
  static const double heroCard = 20.0;
  static const double bottomSheet = 24.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryBlue,
        surface: AppColors.primarySurface,
        onSurface: AppColors.primaryText,
        error: AppColors.error,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryText),
        titleTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.primarySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primarySurface,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryAccent;
            }
            return AppColors.secondaryBackground;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.secondaryText;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}