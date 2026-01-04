import 'package:flutter/material.dart';

/// Design tokens for the glassmorphic design system.
///
/// This class provides consistent values for spacing, sizing, animations,
/// and visual properties across the entire application.
abstract class DesignTokens {
  // ============================================================
  // SPACING (8px base grid)
  // ============================================================

  static const double space0 = 0;
  static const double space1 = 4; // 0.5x
  static const double space2 = 8; // 1x (base unit)
  static const double space3 = 12; // 1.5x
  static const double space4 = 16; // 2x
  static const double space5 = 20; // 2.5x
  static const double space6 = 24; // 3x
  static const double space7 = 32; // 4x
  static const double space8 = 40; // 5x
  static const double space9 = 48; // 6x
  static const double space10 = 64; // 8x

  // ============================================================
  // BORDER RADIUS (standardized from tools/projects toggle)
  // ============================================================

  static const double radiusNone = 0;
  static const double radiusXs = 4; // Small chips, tags
  static const double radiusSm = 8; // Buttons, inputs, inner pills, menu items
  static const double radiusMd = 10; // Containers, panels, outer wrappers
  static const double radiusLg = 22; // Dialogs, modals
  static const double radiusFull = 999; // Pills, avatars

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================

  static const Duration durationInstant = Duration.zero;
  static const Duration durationFast = Duration(milliseconds: 120);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 280);
  static const Duration durationSlow = Duration(milliseconds: 400);
  static const Duration durationSlowest = Duration(milliseconds: 600);

  // ============================================================
  // ANIMATION CURVES
  // ============================================================

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveEnter = Curves.easeOut;
  static const Curve curveExit = Curves.easeIn;
  static const Curve curveEmphasis = Curves.easeInOutCubic;
  static const Curve curveSpring = Curves.elasticOut;
  static const Curve curveDecelerate = Curves.decelerate;

  // ============================================================
  // GLASS BLUR LEVELS
  // ============================================================

  static const double blurNone = 0;
  static const double blurSubtle = 6;
  static const double blurLight = 10;
  static const double blurMedium = 14;
  static const double blurHeavy = 20;

  // ============================================================
  // ICON SIZES
  // ============================================================

  static const double iconXs = 12;
  static const double iconSm = 14;
  static const double iconMd = 16;
  static const double iconLg = 20;
  static const double iconXl = 24;

  // ============================================================
  // COMPONENT HEIGHTS
  // ============================================================

  static const double buttonHeight = 36;
  static const double inputHeight = 44;
  static const double listItemHeight = 56;
  static const double tileHeight = 60;
  static const double headerHeight = 48;
}

/// Depth layers for glass elements.
///
/// Each layer has different blur and opacity values to create
/// visual hierarchy and depth perception.
enum GlassDepth {
  /// Background layer (no glass effect)
  background,

  /// Primary containers (main panels)
  primary,

  /// Secondary elements (list items, tiles)
  secondary,

  /// Interactive elements (buttons, chips)
  interactive,

  /// Floating elements (menus, dialogs)
  floating,
}

/// Shadow presets for glass elements.
///
/// Provides consistent shadow definitions across the design system.
abstract class GlassShadows {
  /// Subtle shadow for minimal depth
  static List<BoxShadow> subtle(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Low elevation shadow
  static List<BoxShadow> low(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// Medium elevation shadow
  static List<BoxShadow> medium(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];

  /// High elevation shadow
  static List<BoxShadow> high(bool isDark) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.10),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Accent glow shadow
  static List<BoxShadow> glow(Color accent, {double intensity = 0.3}) => [
    BoxShadow(
      color: accent.withValues(alpha: intensity),
      blurRadius: 20,
      spreadRadius: -4,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Animation presets for glass transitions.
abstract class GlassTransitions {
  /// Standard hover transition
  static const Duration hoverDuration = Duration(milliseconds: 150);
  static const Curve hoverCurve = Curves.easeOut;

  /// Focus ring appearance
  static const Duration focusDuration = Duration(milliseconds: 200);
  static const Curve focusCurve = Curves.easeOutCubic;

  /// State change (selected, active)
  static const Duration stateDuration = Duration(milliseconds: 250);
  static const Curve stateCurve = Curves.easeInOutCubic;

  /// Panel/container animations
  static const Duration containerDuration = Duration(milliseconds: 280);
  static const Curve containerCurve = Curves.easeOutCubic;

  /// Glow pulse animation
  static const Duration glowPulseDuration = Duration(seconds: 8);
  static const Curve glowPulseCurve = Curves.easeInOut;
}
