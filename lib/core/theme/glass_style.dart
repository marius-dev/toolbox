import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'glass_style_strategy.dart';

export 'design_tokens.dart'
    show GlassDepth, GlassShadows, GlassTransitions, DesignTokens;

/// Glass style enumeration for UI theming.
///
/// This enum provides a simple interface for selecting between different
/// glass morphism styles. Each enum value maps to a concrete strategy
/// implementation that defines the visual characteristics.
enum GlassStyle { clear, tinted }

extension GlassStyleExtension on GlassStyle {
  /// Returns the storage key for serialization.
  String get storageKey {
    switch (this) {
      case GlassStyle.clear:
        return 'clear';
      case GlassStyle.tinted:
        return 'tinted';
    }
  }

  /// Returns the strategy implementation for this glass style.
  ///
  /// This method bridges the enum to the strategy pattern, allowing
  /// the rest of the codebase to work with concrete strategy instances.
  GlassStyleStrategy get strategy {
    switch (this) {
      case GlassStyle.clear:
        return const ClearGlassStrategy();
      case GlassStyle.tinted:
        return const TintedGlassStrategy();
    }
  }

  /// Creates a GlassStyle from a storage key string.
  static GlassStyle fromString(String? value) {
    switch (value) {
      case 'clear':
        return GlassStyle.clear;
      case 'tinted':
        return GlassStyle.tinted;
      default:
        return GlassStyle.tinted;
    }
  }
}

/// Palette generator for glass morphism effects.
///
/// This class now uses composition with [GlassStyleStrategy] instead of
/// conditional logic, following the Strategy pattern for better maintainability
/// and extensibility.
class GlassStylePalette {
  GlassStylePalette({
    required this.style,
    required this.isDark,
    required this.accentColor,
  }) : _strategy = style.strategy;

  final GlassStyle style;
  final bool isDark;
  final Color accentColor;
  final GlassStyleStrategy _strategy;

  factory GlassStylePalette.fromContext(
    BuildContext context, {
    required GlassStyle style,
    required Color accentColor,
  }) {
    return GlassStylePalette(
      style: style,
      isDark: Theme.of(context).brightness == Brightness.dark,
      accentColor: accentColor,
    );
  }

  /// Returns the blur sigma for backdrop filters.
  double get blurSigma => _strategy.blurSigma;

  /// Returns the surface opacity for this palette.
  double get _surfaceOpacity => _strategy.surfaceOpacity(isDark);

  /// Returns the base color for glass surfaces.
  Color get baseColor => Colors.white.withOpacity(_surfaceOpacity);

  /// Returns the accent overlay opacity.
  double get accentOpacity => _strategy.accentOpacity(isDark);

  /// Returns the inner color with optional accent tinting.
  Color get innerColor {
    final base = baseColor;
    if (accentOpacity <= 0) return base;
    return Color.alphaBlend(accentColor.withOpacity(accentOpacity), base);
  }

  /// Returns the border color for glass elements.
  Color get borderColor {
    final opacity = _strategy.borderOpacity(isDark);
    return isDark
        ? Colors.white.withOpacity(opacity)
        : Colors.black.withOpacity(opacity);
  }

  /// Returns the gradient for glass surfaces.
  LinearGradient get gradient {
    if (accentOpacity > 0) {
      // Tinted style with gradient
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          innerColor,
          Color.alphaBlend(accentColor.withOpacity(0.08), innerColor),
        ],
      );
    } else {
      // Clear style with flat color
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [innerColor, innerColor],
      );
    }
  }

  /// Returns the background gradient colors.
  List<Color> get backgroundGradient {
    final opacities = _strategy.backgroundGradientOpacities(isDark);
    final accentOverlayOpacity = _strategy.backgroundAccentOpacity(isDark);

    final start = isDark
        ? Color(0xFF03050C).withOpacity(opacities[0])
        : Colors.white.withOpacity(opacities[0]);

    final middleBase = isDark
        ? Color(0xFF05070F).withOpacity(opacities[1])
        : Colors.white.withOpacity(opacities[1]);

    final end = isDark
        ? Color(0xFF0E1324).withOpacity(opacities[2])
        : Color(0xFFF5F6FB).withOpacity(opacities[2]);

    final middle = accentOverlayOpacity > 0
        ? Color.alphaBlend(
            accentColor.withOpacity(accentOverlayOpacity),
            middleBase,
          )
        : middleBase;

    return [start, middle, end];
  }

  /// Returns the glow color for ambient effects.
  Color get glowColor => accentColor.withOpacity(_strategy.glowOpacity());

  /// Returns the shadow configuration for glass elements.
  List<BoxShadow>? get shadow {
    final config = _strategy.shadowConfig(isDark);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: config.opacity),
        blurRadius: config.blurRadius,
        offset: Offset(0, config.offsetY),
      ),
    ];
  }

  /// Returns the blur sigma for a specific depth layer.
  double blurForDepth(GlassDepth depth) => _strategy.blurForDepth(depth);

  /// Returns the surface opacity for a specific depth layer.
  double opacityForDepth(GlassDepth depth) =>
      _strategy.opacityForDepth(depth, isDark);

  /// Returns the highlight line opacity for top edge effects.
  double get highlightLineOpacity => _strategy.highlightLineOpacity(isDark);

  /// Returns the surface color for a specific depth layer.
  Color surfaceColorForDepth(GlassDepth depth) {
    final opacity = opacityForDepth(depth);
    return Colors.white.withValues(alpha: opacity);
  }
}

/// Helper function to create solid dialog backgrounds.
Color solidDialogBackground(GlassStylePalette palette, ThemeData theme) {
  return Color.alphaBlend(palette.innerColor, theme.colorScheme.surface);
}
