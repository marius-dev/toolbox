import 'package:flutter/material.dart';

import '../di/service_locator.dart';
import '../utils/compact_layout.dart';
import 'glass_style.dart';
import 'theme_colors.dart';
import 'theme_provider.dart';

/// BuildContext extensions for convenient access to theme utilities.
///
/// These extensions eliminate repetitive code by providing shorthand access
/// to common theme operations following the DRY principle.
extension ThemeContextExtensions on BuildContext {
  /// Returns true if the current theme brightness is dark.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Returns true if the current theme brightness is light.
  bool get isLight => !isDark;

  /// Returns the current ThemeData.
  ThemeData get theme => Theme.of(this);

  /// Returns the current accent color from ThemeProvider.
  Color get accentColor => getIt<ThemeProvider>().accentColor;

  /// Returns the current glass style from ThemeProvider.
  GlassStyle get glassStyle => getIt<ThemeProvider>().glassStyle;

  /// Returns a GlassStylePalette for the current context.
  ///
  /// Optionally accepts custom style and accent color.
  GlassStylePalette glassColors({
    GlassStyle? style,
    Color? accentColor,
  }) {
    final themeProvider = getIt<ThemeProvider>();
    return GlassStylePalette.fromContext(
      this,
      style: style ?? themeProvider.glassStyle,
      accentColor: accentColor ?? themeProvider.accentColor,
    );
  }

  /// Returns a surface color with the given opacity.
  ///
  /// See [ThemeColors.surfaceColor]
  Color surfaceColor({required double opacity}) {
    return ThemeColors.surfaceColor(this, opacity: opacity);
  }

  /// Returns the base surface color.
  ///
  /// See [ThemeColors.baseSurface]
  Color get baseSurface => ThemeColors.baseSurface(this);

  /// Returns the border color.
  ///
  /// See [ThemeColors.borderColor]
  Color borderColor({double? opacity}) {
    return ThemeColors.borderColor(this, opacity: opacity);
  }

  /// Returns an accent color with opacity.
  ///
  /// See [ThemeColors.accentWithOpacity]
  Color accentWithOpacity({
    Color? accentColor,
    required double darkOpacity,
    required double lightOpacity,
  }) {
    return ThemeColors.accentWithOpacity(
      this,
      accentColor ?? this.accentColor,
      darkOpacity: darkOpacity,
      lightOpacity: lightOpacity,
    );
  }

  /// Returns a highlight color.
  ///
  /// See [ThemeColors.highlightColor]
  Color highlightColor({
    Color? accentColor,
    double? darkOpacity,
    double? lightOpacity,
  }) {
    return ThemeColors.highlightColor(
      this,
      accentColor ?? this.accentColor,
      darkOpacity: darkOpacity,
      lightOpacity: lightOpacity,
    );
  }

  /// Returns the icon color.
  ///
  /// See [ThemeColors.iconColor]
  Color iconColor({double? opacity}) {
    return ThemeColors.iconColor(this, opacity: opacity);
  }

  /// Returns the text color.
  ///
  /// See [ThemeColors.textColor]
  Color textColor({double? opacity}) {
    return ThemeColors.textColor(this, opacity: opacity);
  }

  /// Returns the secondary text color.
  ///
  /// See [ThemeColors.secondaryTextColor]
  Color get secondaryTextColor => ThemeColors.secondaryTextColor(this);

  /// Returns the divider color.
  ///
  /// See [ThemeColors.dividerColor]
  Color get dividerColor => ThemeColors.dividerColor(this);

  /// Returns the accent border color.
  ///
  /// See [ThemeColors.accentBorderColor]
  Color accentBorderColor({Color? accentColor, Color? baseBorder}) {
    return ThemeColors.accentBorderColor(
      this,
      accentColor ?? this.accentColor,
      baseBorder: baseBorder,
    );
  }
}

/// BuildContext extensions for CompactLayout utilities.
///
/// These extensions provide convenient access to responsive layout scaling.
extension LayoutContextExtensions on BuildContext {
  /// Returns the current compact layout scale factor.
  double get compactScale => CompactLayout.scale(this);

  /// Scales a value using the compact layout scale.
  double compactValue(double value) => CompactLayout.value(this, value);

  /// Creates a BorderRadius scaled for compact layout.
  BorderRadius compactRadius(double radius) {
    return BorderRadius.circular(compactValue(radius));
  }

  /// Creates symmetric EdgeInsets scaled for compact layout.
  EdgeInsets compactPadding({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return CompactLayout.symmetric(
      this,
      horizontal: horizontal,
      vertical: vertical,
    ) as EdgeInsets;
  }

  /// Creates EdgeInsets with only specified sides scaled for compact layout.
  EdgeInsets compactPaddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return CompactLayout.only(
      this,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    ) as EdgeInsets;
  }
}
