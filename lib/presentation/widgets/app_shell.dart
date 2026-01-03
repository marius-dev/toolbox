import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_provider.dart';

class GlowSpec {
  final Alignment alignment;
  final Offset offset;
  final double size;
  final double opacity;
  final double angle;
  final double thickness;

  const GlowSpec({
    required this.alignment,
    required this.offset,
    required this.size,
    this.opacity = 1,
    this.angle = -0.35,
    this.thickness = 0.42,
  });
}

class AppShell extends StatelessWidget {
  final Widget Function(BuildContext context, GlassStylePalette palette)
  builder;
  final bool useSafeArea;
  final List<GlowSpec>? glows;
  final EdgeInsetsGeometry? padding;
  final double? blurSigma;

  const AppShell({
    super.key,
    required this.builder,
    this.useSafeArea = true,
    this.glows,
    this.padding,
    this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: getIt<ThemeProvider>(),
      builder: (context, _) {
        final palette = GlassStylePalette.fromContext(
          context,
          style: context.glassStyle,
          accentColor: context.accentColor,
        );
        final borderRadius = BorderRadius.circular(DesignTokens.radius2xl);
        final sigma = blurSigma ?? palette.blurSigma;
        // Very subtle aurora glows - vibrant but not overwhelming
        final glowSpecs =
            glows ??
            const [
              GlowSpec(
                alignment: Alignment.topLeft,
                offset: Offset(-48, -180),
                size: 260,
                opacity: 0.25, // Much subtler
                angle: -0.55,
                thickness: 0.24,
              ),
              GlowSpec(
                alignment: Alignment.topRight,
                offset: Offset(160, -80),
                size: 200,
                opacity: 0.15, // Much subtler
                angle: 0.48,
                thickness: 0.20,
              ),
              GlowSpec(
                alignment: Alignment.bottomRight,
                offset: Offset(90, 240),
                size: 300,
                opacity: 0.30, // Much subtler
                angle: -0.2,
                thickness: 0.26,
              ),
            ];

        Widget content = builder(context, palette);
        if (useSafeArea) {
          content = SafeArea(child: content);
        }
        if (padding != null) {
          content = Padding(padding: padding!, child: content);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.backgroundGradient,
              ),
              boxShadow: palette.shadow,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: palette.backgroundGradient,
                          ),
                          border: Border.all(color: palette.borderColor),
                        ),
                      ),
                    ),
                    // Subtle overlay for depth
                    Positioned.fill(
                      child: ColoredBox(
                        color: palette.isDark
                            ? Colors.black.withValues(alpha: 0.10)
                            : Colors.white.withValues(alpha: 0.02),
                      ),
                    ),
                    _GlowLayer(
                      glowColor: palette.glowColor,
                      specs: glowSpecs,
                      isDark: palette.isDark,
                    ),
                    content,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GlowLayer extends StatelessWidget {
  final Color glowColor;
  final List<GlowSpec> specs;
  final bool isDark;

  const _GlowLayer({
    required this.glowColor,
    required this.specs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: specs
            .map(
              (spec) => Align(
                alignment: spec.alignment,
                child: Transform.translate(
                  offset: spec.offset,
                  child: _AuroraBand(
                    color: glowColor,
                    width: spec.size * 1.35,
                    height: spec.size * spec.thickness,
                    angle: spec.angle,
                    opacity: spec.opacity,
                    isDark: isDark,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AuroraBand extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final double angle;
  final double opacity;
  final bool isDark;

  const _AuroraBand({
    required this.color,
    required this.width,
    required this.height,
    required this.angle,
    required this.opacity,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // More sophisticated color derivation for subtle aurora
    final hsl = HSLColor.fromColor(color);
    final highlight = hsl
        .withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0))
        .toColor();
    final depth = hsl
        .withSaturation((hsl.saturation - 0.15).clamp(0.0, 1.0))
        .withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0))
        .toColor();
    final secondary = hsl.withHue((hsl.hue + 30) % 360).toColor();

    return Transform.rotate(
      angle: angle,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: height * 1.4, // More blur for softer appearance
          sigmaY: height * 1.4,
        ),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: LinearGradient(
              begin: const Alignment(-1.2, 0.8),
              end: const Alignment(1.1, -0.6),
              colors: [
                highlight.withValues(alpha: opacity * 0.25),
                color.withValues(alpha: opacity * 0.08),
                secondary.withValues(alpha: opacity * 0.12),
                depth.withValues(alpha: opacity * 0.20),
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
            ),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: LinearGradient(
              begin: const Alignment(-0.8, -1.2),
              end: const Alignment(0.8, 1.0),
              colors: [
                Colors.white.withValues(
                  alpha: opacity * (isDark ? 0.06 : 0.04),
                ),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
