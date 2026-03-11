import 'package:flutter/material.dart';
import 'app_colors.dart';

enum AppThemeType { light, dark, midnight, amoled }

class AppTheme {
  static ThemeData getTheme(AppThemeType type, Color accentColor) {
    switch (type) {
      case AppThemeType.light:
        return _lightTheme(accentColor);
      case AppThemeType.dark:
        return _darkTheme(accentColor);
      case AppThemeType.midnight:
        return _midnightTheme(accentColor);
      case AppThemeType.amoled:
        return _amoledTheme(accentColor);
    }
  }

  static ThemeData _lightTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: accent,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  static ThemeData _darkTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: accent,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkCard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.darkCard,
      ),
    );
  }

  static ThemeData _midnightTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: accent,
      scaffoldBackgroundColor: AppColors.midnightBg,
      cardColor: AppColors.midnightCard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.midnightSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.midnightCard,
      ),
    );
  }

  static ThemeData _amoledTheme(Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: accent,
      scaffoldBackgroundColor: AppColors.amoledBg,
      cardColor: AppColors.amoledCard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.amoledSurface,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppColors.amoledCard,
      ),
    );
  }
}
