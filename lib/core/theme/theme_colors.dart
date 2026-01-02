import 'package:flutter/material.dart';

/// Centralized theme color utilities to eliminate duplication of color/opacity patterns.
///
/// This class provides consistent color calculations based on theme brightness,
/// following the DRY principle by centralizing all repeated color/opacity logic.
class ThemeColors {
  ThemeColors._();

  /// Returns a surface color with the given opacity, adjusted for theme brightness.
  ///
  /// Dark theme: white with opacity
  /// Light theme: black with opacity
  static Color surfaceColor(BuildContext context, {required double opacity}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(opacity)
        : Colors.black.withOpacity(opacity);
  }

  /// Returns the base surface color for glass/panel backgrounds.
  ///
  /// Dark theme: white 5% opacity
  /// Light theme: black 2% opacity
  static Color baseSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.02);
  }

  /// Returns the standard border color for glass components.
  ///
  /// Dark theme: white 10-12% opacity
  /// Light theme: black 8% opacity
  static Color borderColor(BuildContext context, {double? opacity}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultOpacity = isDark ? 0.12 : 0.08;
    return isDark
        ? Colors.white.withOpacity(opacity ?? defaultOpacity)
        : Colors.black.withOpacity(opacity ?? defaultOpacity);
  }

  /// Returns an accent color with opacity adjusted for theme brightness.
  ///
  /// Accepts optional dark/light opacity values for fine-tuning.
  static Color accentWithOpacity(
    BuildContext context,
    Color accentColor, {
    required double darkOpacity,
    required double lightOpacity,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return accentColor.withOpacity(isDark ? darkOpacity : lightOpacity);
  }

  /// Returns a highlight color by blending accent with base surface.
  ///
  /// Used for gradient effects and hover states.
  static Color highlightColor(
    BuildContext context,
    Color accentColor, {
    double? darkOpacity,
    double? lightOpacity,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = isDark ? (darkOpacity ?? 0.18) : (lightOpacity ?? 0.08);
    return accentColor.withOpacity(opacity);
  }

  /// Returns the default icon color for the current theme.
  ///
  /// Dark theme: white 90% opacity
  /// Light theme: black 65% opacity
  static Color iconColor(BuildContext context, {double? opacity}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (opacity != null) {
      return isDark
          ? Colors.white.withOpacity(opacity)
          : Colors.black.withOpacity(opacity);
    }
    return isDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.65);
  }

  /// Returns the default text color for the current theme.
  ///
  /// Dark theme: white 90% opacity
  /// Light theme: black 85% opacity
  static Color textColor(BuildContext context, {double? opacity}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (opacity != null) {
      return isDark
          ? Colors.white.withOpacity(opacity)
          : Colors.black.withOpacity(opacity);
    }
    return isDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.85);
  }

  /// Returns a secondary/muted text color for the current theme.
  ///
  /// Dark theme: white 60% opacity
  /// Light theme: black 50% opacity
  static Color secondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.6)
        : Colors.black.withOpacity(0.5);
  }

  /// Returns a divider color for the current theme.
  ///
  /// Dark theme: white 8% opacity
  /// Light theme: black 6% opacity
  static Color dividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
  }

  /// Returns the standard dialog barrier color.
  ///
  /// Black with 78% opacity (consistent across themes)
  static Color dialogBarrierColor() {
    return Colors.black.withOpacity(0.78);
  }

  /// Creates a border with accent color blended with base border.
  ///
  /// Used for tinted/highlighted borders.
  static Color accentBorderColor(
    BuildContext context,
    Color accentColor, {
    Color? baseBorder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = baseBorder ?? borderColor(context);
    final accentOpacity = isDark ? 0.25 : 0.18;
    return Color.alphaBlend(
      accentColor.withOpacity(accentOpacity),
      base,
    );
  }

  /// Returns shadow color for the given accent.
  ///
  /// Used for glow effects in dark mode.
  static Color shadowColor(Color accentColor, {double opacity = 0.2}) {
    return accentColor.withOpacity(opacity);
  }
}
