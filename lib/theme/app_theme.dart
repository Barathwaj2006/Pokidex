import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBackground = Color(0xFFF5F7FB);
  static const Color secondaryBackground = Color(0xFFEEF1F7);
  static const Color primarySurface = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF111111);
  static const Color secondaryText = Color(0xFF666A73);
  static const Color mutedText = Color(0xFF969AA3);
  static const Color border = Color(0xFFE7E9EE);

  static const Color primaryAccent = Color(0xFF3478F6);
  static const Color secondaryBlue = Color(0xFF5D8FF2);
  static const Color softBlue = Color(0xFFE8F0FF);

  static const Color success = Color(0xFF43C59E);
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFEF6B6B);
  static const Color darkSurface = Color(0xFF17283D);
}

class AppRadius {
  static const double chip = 10.0;
  static const double button = 14.0;
  static const double card = 18.0;
  static const double heroCard = 24.0;
  static const double bottomSheet = 28.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryBlue,
        surface: AppColors.primarySurface,
        onSurface: AppColors.primaryText,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.primaryText),
        titleTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.primarySurface,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
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
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryAccent;
            }
            return AppColors.primarySurface;
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