import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Ward Water Dashboard';

  static const List<String> wards = [
    'Ward A (Central)',
    'Ward B (North)',
    'Ward C (East)',
    'Ward D (South)',
    'Ward E (West)',
  ];

  static const List<String> valveStates = [
    'OPEN',
    'CLOSED',
    'HALF-OPEN',
  ];
}

class AppColors {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryDarkBlue = Color(0xFF1565C0);
  static const Color accentCyan = Color(0xFF00ACC1);

  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE53935);
  static const Color infoPurple = Color(0xFF8E24AA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
    );
  }
}
