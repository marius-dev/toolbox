import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project_launcher/core/theme/theme_provider.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(brightness);
    final backgroundColor = isDark
        ? const Color(0xFF050A14)
        : const Color(0xFFF5F6FB);
    final surfaceColor = isDark ? const Color(0xFF151B2F) : Colors.white;
    final elevatedSurface = isDark
        ? const Color(0xFF1D2440)
        : Colors.white.withOpacity(0.96);
    final outlineColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final faintOutline = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'SF Pro',
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      dialogBackgroundColor: elevatedSurface,
      canvasColor: Colors.transparent,
      dividerColor: faintOutline,
      popupMenuTheme: PopupMenuThemeData(
        color: elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: outlineColor),
        ),
        elevation: 0,
        textStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 13,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedSurface,
        hintStyle: TextStyle(
          color: isDark ? Colors.white.withOpacity(0.6) : Colors.black45,
          fontSize: 13,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),

      cardTheme: CardThemeData(
        color: elevatedSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: faintOutline),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: outlineColor),
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 14,
        ),
      ),

      iconTheme: IconThemeData(
        color: isDark ? Colors.white70 : Colors.black54,
        size: 20,
      ),

      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 13,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        titleLarge: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: surfaceColor,
        selectedTileColor: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.1),
      ),
    );
  }

  static ColorScheme _buildColorScheme(Brightness brightness) {
    final accentColor = ThemeProvider.instance.accentColor;
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF050A14)
        : const Color(0xFFF5F6FB);
    final surface = isDark ? const Color(0xFF151B2F) : Colors.white;

    return ColorScheme(
      brightness: brightness,
      primary: accentColor,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: surface,
      onSurface: isDark ? Colors.white : Colors.black87,
      background: background,
      onBackground: isDark ? Colors.white : Colors.black87,
    );
  }
}
