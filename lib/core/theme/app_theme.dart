import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project_launcher/core/theme/theme_provider.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(brightness);

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'SF Pro',
      scaffoldBackgroundColor: Colors.transparent,
      useMaterial3: true,

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: isDark ? Colors.white70 : Colors.black54,
        size: 20,
      ),

      // Text theme
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 13,
        ),
        titleMedium: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  static ColorScheme _buildColorScheme(Brightness brightness) {
    final accentColor = ThemeProvider.instance.accentColor;
    final isDark = brightness == Brightness.dark;

    return ColorScheme(
      brightness: brightness,
      primary: accentColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: isDark ? const Color(0xFF0B0D14) : Colors.white,
      onBackground: isDark ? Colors.white : Colors.black87,
      surface: isDark
          ? Colors.black.withOpacity(0.2)
          : Colors.white.withOpacity(0.9),
      onSurface: isDark ? Colors.white : Colors.black87,
    );
  }
}
