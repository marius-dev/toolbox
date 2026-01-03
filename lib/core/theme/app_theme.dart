import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project_launcher/core/theme/theme_provider.dart';

import '../di/service_locator.dart';
import 'design_tokens.dart';
import 'glass_style.dart';

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = _buildColorScheme(brightness);
    final glassStyle = getIt<ThemeProvider>().glassStyle;
    final isClearGlass = glassStyle == GlassStyle.clear;

    // Refined colors for modern minimal aesthetic
    final backgroundColor = isDark
        ? (isClearGlass ? const Color(0xFF02040A) : const Color(0xFF040810))
        : (isClearGlass ? const Color(0xFFFEFEFE) : const Color(0xFFF8F9FC));
    final surfaceColor = isDark
        ? (isClearGlass ? const Color(0xFF0E1220) : const Color(0xFF121828))
        : (isClearGlass ? Colors.white.withValues(alpha: 0.98) : Colors.white);
    final elevatedSurface = isDark
        ? (isClearGlass ? const Color(0xFF161A2C) : const Color(0xFF1A2038))
        : Colors.white.withValues(alpha: isClearGlass ? 0.95 : 0.98);
    final outlineColor = isDark
        ? Colors.white.withValues(alpha: isClearGlass ? 0.05 : 0.06)
        : Colors.black.withValues(alpha: isClearGlass ? 0.03 : 0.05);
    final faintOutline = isDark
        ? Colors.white.withValues(alpha: isClearGlass ? 0.02 : 0.03)
        : Colors.black.withValues(alpha: isClearGlass ? 0.015 : 0.03);

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
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          side: BorderSide(color: outlineColor),
        ),
        elevation: 0,
        textStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 12,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedSurface,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.4),
          fontSize: 12,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3,
          vertical: DesignTokens.space2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
        ),
      ),

      cardTheme: CardThemeData(
        color: elevatedSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(color: faintOutline),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: elevatedSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(color: outlineColor),
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 13,
        ),
      ),

      iconTheme: IconThemeData(
        color: isDark ? Colors.white70 : Colors.black54,
        size: 16,
      ),

      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 13,
          height: 1.3,
        ),
        bodyMedium: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 12,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        titleLarge: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        tileColor: surfaceColor,
        selectedTileColor:
            colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
      ),
    );
  }

  static ColorScheme _buildColorScheme(Brightness brightness) {
    final accentColor = getIt<ThemeProvider>().accentColor;
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF121828) : Colors.white;
    final surfaceContainer = isDark
        ? const Color(0xFF040810)
        : const Color(0xFFF8F9FC);

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
      surfaceContainerLowest: surfaceContainer,
      surfaceContainerLow: surfaceContainer,
      surfaceContainer: surfaceContainer,
    );
  }
}
