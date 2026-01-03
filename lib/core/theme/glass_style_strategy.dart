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
class ClearGlassStrategy extends GlassStyleStrategy {
  const ClearGlassStrategy();

  @override
  String get storageKey => 'clear';

  @override
  String get displayName => 'Clear';

  @override
  double get blurSigma => 16.0;

  @override
  double surfaceOpacity(bool isDark) => isDark ? 0.08 : 0.24;

  @override
  double accentOpacity(bool isDark) => 0.0; // No accent tint

  @override
  double borderOpacity(bool isDark) => isDark ? 0.12 : 0.04;

  @override
  List<double> backgroundGradientOpacities(bool isDark) {
    if (isDark) {
      return [0.32, 0.3, 0.42]; // start, middle, end
    } else {
      return [0.55, 0.5, 0.38];
    }
  }

  @override
  double backgroundAccentOpacity(bool isDark) => 0.0; // No accent overlay

  @override
  double glowOpacity() => 0.25;

  @override
  ShadowConfig shadowConfig(bool isDark) {
    return ShadowConfig(
      opacity: isDark ? 0.25 : 0.08,
      blurRadius: 18.0,
      offsetY: 10.0,
    );
  }
}

/// Tinted glass style strategy with stronger accent colors and deeper effects.
class TintedGlassStrategy extends GlassStyleStrategy {
  const TintedGlassStrategy();

  @override
  String get storageKey => 'tinted';

  @override
  String get displayName => 'Tinted';

  @override
  double get blurSigma => 24.0;

  @override
  double surfaceOpacity(bool isDark) => isDark ? 0.12 : 0.32;

  @override
  double accentOpacity(bool isDark) => isDark ? 0.2 : 0.15;

  @override
  double borderOpacity(bool isDark) => isDark ? 0.2 : 0.08;

  @override
  List<double> backgroundGradientOpacities(bool isDark) {
    if (isDark) {
      return [0.45, 0.38, 0.6]; // start, middle, end
    } else {
      return [0.82, 0.8, 0.65];
    }
  }

  @override
  double backgroundAccentOpacity(bool isDark) => isDark ? 0.18 : 0.08;

  @override
  double glowOpacity() => 0.6;

  @override
  ShadowConfig shadowConfig(bool isDark) {
    return ShadowConfig(
      opacity: isDark ? 0.55 : 0.18,
      blurRadius: 30.0,
      offsetY: 16.0,
    );
  }
}
