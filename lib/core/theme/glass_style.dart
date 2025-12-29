import 'package:flutter/material.dart';

enum GlassStyle {
  clear,
  tinted,
}

extension GlassStyleExtension on GlassStyle {
  String get storageKey {
    switch (this) {
      case GlassStyle.clear:
        return 'clear';
      case GlassStyle.tinted:
        return 'tinted';
    }
  }

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

class GlassStylePalette {
  GlassStylePalette({
    required this.style,
    required this.isDark,
    required this.accentColor,
  });

  final GlassStyle style;
  final bool isDark;
  final Color accentColor;

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

  double get blurSigma => style == GlassStyle.clear ? 16 : 24;

  double get _surfaceOpacity => isDark
      ? (style == GlassStyle.clear ? 0.08 : 0.12)
      : (style == GlassStyle.clear ? 0.24 : 0.32);

  Color get baseColor => Colors.white.withOpacity(_surfaceOpacity);

  double get accentOpacity => style == GlassStyle.tinted
      ? (isDark ? 0.2 : 0.15)
      : 0.0;

  Color get innerColor {
    final base = baseColor;
    if (accentOpacity <= 0) return base;
    return Color.alphaBlend(accentColor.withOpacity(accentOpacity), base);
  }

  Color get borderColor => isDark
      ? Colors.white.withOpacity(style == GlassStyle.tinted ? 0.2 : 0.12)
      : Colors.black.withOpacity(style == GlassStyle.tinted ? 0.08 : 0.04);

  LinearGradient get gradient => style == GlassStyle.tinted
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            innerColor,
            Color.alphaBlend(accentColor.withOpacity(0.08), innerColor),
          ],
        )
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            innerColor,
            innerColor,
          ],
        );

  List<Color> get backgroundGradient {
    final start = isDark
        ? Color(0xFF03050C).withOpacity(style == GlassStyle.clear ? 0.32 : 0.45)
        : Colors.white.withOpacity(style == GlassStyle.clear ? 0.55 : 0.82);
    final middleBase = isDark
        ? Color(0xFF05070F).withOpacity(style == GlassStyle.clear ? 0.3 : 0.38)
        : Colors.white.withOpacity(style == GlassStyle.clear ? 0.5 : 0.8);
    final end = isDark
        ? Color(0xFF0E1324).withOpacity(style == GlassStyle.clear ? 0.42 : 0.6)
        : Color(0xFFF5F6FB).withOpacity(style == GlassStyle.clear ? 0.38 : 0.65);
    final overlayOpacity =
        style == GlassStyle.tinted ? (isDark ? 0.18 : 0.08) : 0.0;
    final middle = Color.alphaBlend(
      accentColor.withOpacity(overlayOpacity),
      middleBase,
    );

    return [start, middle, end];
  }

  Color get glowColor =>
      accentColor.withOpacity(style == GlassStyle.tinted ? 0.6 : 0.25);

  List<BoxShadow>? get shadow => [
        BoxShadow(
          color: Colors.black.withOpacity(
            isDark
                ? (style == GlassStyle.tinted ? 0.55 : 0.25)
                : (style == GlassStyle.tinted ? 0.18 : 0.08),
          ),
          blurRadius: style == GlassStyle.tinted ? 30 : 18,
          offset: Offset(0, style == GlassStyle.tinted ? 16 : 10),
        ),
      ];
}
