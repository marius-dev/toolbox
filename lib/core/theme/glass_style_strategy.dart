import 'design_tokens.dart';

/// Abstract strategy for glass style rendering.
///
/// This interface defines all the visual properties needed to render
/// glass morphism effects. Concrete implementations provide different
/// visual characteristics for various glass styles.
///
/// This follows the Strategy pattern, allowing easy addition of new
/// glass styles without modifying existing code.
abstract class GlassStyleStrategy {
  const GlassStyleStrategy();

  /// Returns the storage key for this style.
  String get storageKey;

  /// Returns the human-readable name of this style.
  String get displayName;

  /// Returns the blur sigma value for backdrop filters.
  double get blurSigma;

  /// Returns the base surface opacity for the given theme brightness.
  double surfaceOpacity(bool isDark);

  /// Returns the accent color overlay opacity for the given theme brightness.
  double accentOpacity(bool isDark);

  /// Returns the border opacity for the given theme brightness.
  double borderOpacity(bool isDark);

  /// Returns the background gradient opacities for start, middle, and end.
  ///
  /// Returns a list of [start, middle, end] opacity values.
  List<double> backgroundGradientOpacities(bool isDark);

  /// Returns the accent overlay opacity for background gradient middle color.
  double backgroundAccentOpacity(bool isDark);

  /// Returns the glow color opacity.
  double glowOpacity();

  /// Returns the shadow configuration.
  ShadowConfig shadowConfig(bool isDark);

  /// Returns the highlight line opacity for top edge glass effect.
  double highlightLineOpacity(bool isDark);

  /// Returns the blur sigma for a specific depth layer.
  double blurForDepth(GlassDepth depth) {
    switch (depth) {
      case GlassDepth.background:
        return 0;
      case GlassDepth.primary:
        return blurSigma;
      case GlassDepth.secondary:
        return blurSigma * 0.6;
      case GlassDepth.interactive:
        return blurSigma * 0.4;
      case GlassDepth.floating:
        return blurSigma * 1.4;
    }
  }

  /// Returns the opacity for a specific depth layer.
  double opacityForDepth(GlassDepth depth, bool isDark) {
    final base = surfaceOpacity(isDark);
    switch (depth) {
      case GlassDepth.background:
        return 0;
      case GlassDepth.primary:
        return base;
      case GlassDepth.secondary:
        return base * 0.8;
      case GlassDepth.interactive:
        return base * 1.3;
      case GlassDepth.floating:
        return isDark ? 0.95 : 0.98;
    }
  }
}

/// Shadow configuration for glass effects.
class ShadowConfig {
  final double opacity;
  final double blurRadius;
  final double offsetY;

  const ShadowConfig({
    required this.opacity,
    required this.blurRadius,
    required this.offsetY,
  });
}

/// Clear glass style strategy with minimal tinting and transparency.
///
/// Modern minimal aesthetic with subtle glass effects.
class ClearGlassStrategy extends GlassStyleStrategy {
  const ClearGlassStrategy();

  @override
  String get storageKey => 'clear';

  @override
  String get displayName => 'Clear';

  @override
  double get blurSigma => 10.0; // Reduced from 16.0

  @override
  double surfaceOpacity(bool isDark) => isDark ? 0.12 : 0.30; // Increased for less transparency

  @override
  double accentOpacity(bool isDark) => 0.0; // No accent tint

  @override
  double borderOpacity(bool isDark) => isDark ? 0.12 : 0.06; // Increased for better visibility

  @override
  List<double> backgroundGradientOpacities(bool isDark) {
    if (isDark) {
      return [0.65, 0.70, 0.80]; // Much more opaque
    } else {
      return [0.85, 0.90, 0.95]; // Nearly opaque
    }
  }

  @override
  double backgroundAccentOpacity(bool isDark) => 0.0; // No accent overlay

  @override
  double glowOpacity() => 0.18; // Reduced from 0.25

  @override
  ShadowConfig shadowConfig(bool isDark) {
    return ShadowConfig(
      opacity: isDark ? 0.12 : 0.04, // Reduced from 0.25 : 0.08
      blurRadius: 12.0, // Reduced from 18.0
      offsetY: 6.0, // Reduced from 10.0
    );
  }

  @override
  double highlightLineOpacity(bool isDark) => isDark ? 0.06 : 0.03;
}

/// Simplified tinted glass style with subtle accent hints.
///
/// Vibrant but simple - accent colors are used sparingly for visual interest
/// without overwhelming the interface.
class TintedGlassStrategy extends GlassStyleStrategy {
  const TintedGlassStrategy();

  @override
  String get storageKey => 'tinted';

  @override
  String get displayName => 'Tinted';

  @override
  double get blurSigma => 12.0;

  @override
  double surfaceOpacity(bool isDark) => isDark ? 0.15 : 0.35;

  @override
  // Significantly reduced accent - subtle hint instead of prominent color
  double accentOpacity(bool isDark) => isDark ? 0.04 : 0.05;

  @override
  double borderOpacity(bool isDark) => isDark ? 0.14 : 0.08;

  @override
  List<double> backgroundGradientOpacities(bool isDark) {
    if (isDark) {
      return [0.75, 0.80, 0.85]; // Much more opaque
    } else {
      return [0.90, 0.92, 0.95]; // Nearly opaque
    }
  }

  @override
  // Minimal accent in background - just a hint of color
  double backgroundAccentOpacity(bool isDark) => isDark ? 0.03 : 0.02;

  @override
  // Reduced glow for subtler ambient effect
  double glowOpacity() => 0.20;

  @override
  ShadowConfig shadowConfig(bool isDark) {
    return ShadowConfig(
      opacity: isDark ? 0.20 : 0.08,
      blurRadius: 14.0,
      offsetY: 6.0,
    );
  }

  @override
  double highlightLineOpacity(bool isDark) => isDark ? 0.08 : 0.04;
}
