import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/glass_style.dart';
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
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final palette = GlassStylePalette.fromContext(
          context,
          style: ThemeProvider.instance.glassStyle,
          accentColor: ThemeProvider.instance.accentColor,
        );
        final borderRadius = BorderRadius.circular(26);
        final sigma = blurSigma ?? palette.blurSigma;
        final glowSpecs =
            glows ??
            const [
              GlowSpec(
                alignment: Alignment.topLeft,
                offset: Offset(-36, -160),
                size: 320,
                opacity: 0.7,
                angle: -0.55,
                thickness: 0.36,
              ),
              GlowSpec(
                alignment: Alignment.topRight,
                offset: Offset(140, -60),
                size: 260,
                opacity: 0.36,
                angle: 0.48,
                thickness: 0.32,
              ),
              GlowSpec(
                alignment: Alignment.bottomRight,
                offset: Offset(72, 200),
                size: 420,
                opacity: 0.82,
                angle: -0.2,
                thickness: 0.4,
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
                    Positioned.fill(
                      child: ColoredBox(
                        color: palette.isDark
                            ? Colors.black.withOpacity(0.16)
                            : Colors.white.withOpacity(0.04),
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

  Color _tint(Color target, double amount) {
    final blendWith = isDark ? Colors.white : Colors.black;
    return Color.lerp(target, blendWith, amount)!;
  }

  @override
  Widget build(BuildContext context) {
    final halo = _tint(color, 0.18);
    final highlight = _tint(color, isDark ? 0.52 : 0.68);
    final depth = _tint(color, isDark ? 0.22 : 0.16);

    return Transform.rotate(
      angle: angle,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: height * 0.9,
          sigmaY: height * 0.9,
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
                highlight.withOpacity(opacity * 0.6),
                color.withOpacity(opacity * 0.18),
                depth.withOpacity(opacity * 0.6),
                halo.withOpacity(opacity * 0.2),
              ],
              stops: const [0.0, 0.38, 0.78, 1.0],
            ),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: LinearGradient(
              begin: const Alignment(-0.8, -1.2),
              end: const Alignment(0.8, 1.0),
              colors: [
                Colors.white.withOpacity(opacity * (isDark ? 0.14 : 0.1)),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
