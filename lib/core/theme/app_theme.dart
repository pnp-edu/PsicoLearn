import 'package:flutter/material.dart';

class AppTheme {
  // Shared accent color
  static const Color accentColor = Color(0xFF4FD1C5);

  // Dark palette (kept for backward compat)
  static const Color background = Color(0xFF000000);
  static const Color cardColor = Color(0xFF121212);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9E9E9E);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7);
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final surface = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F0F5);
    final onSurface = isDark ? Colors.white : Colors.black87;
    final textSec = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF666666);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      primaryColor: accentColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accentColor,
        onPrimary: Colors.black,
        secondary: accentColor,
        onSecondary: Colors.black,
        surface: surface,
        onSurface: onSurface,
        error: Colors.red,
        onError: Colors.white,
      ),
      cardColor: cardBg,
      cardTheme: CardThemeData(
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardBg,
        foregroundColor: onSurface,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: isDark ? accentColor : Colors.black,
        unselectedItemColor: textSec,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: onSurface),
        bodyMedium: TextStyle(color: onSurface),
        bodySmall: TextStyle(color: textSec),
        labelLarge: TextStyle(color: onSurface),
        labelMedium: TextStyle(color: textSec),
        labelSmall: TextStyle(color: textSec),
      ).apply(bodyColor: onSurface, displayColor: onSurface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
