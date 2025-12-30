import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_provider.dart';

class GlowSpec {
  final Alignment alignment;
  final Offset offset;
  final double size;
  final double opacity;

  const GlowSpec({
    required this.alignment,
    required this.offset,
    required this.size,
    this.opacity = 1,
  });
}

class AppShell extends StatelessWidget {
  final Widget Function(BuildContext context, GlassStylePalette palette) builder;
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
        final glowSpecs = glows ??
            const [
              GlowSpec(
                alignment: Alignment.topLeft,
            offset: Offset(-40, -120),
            size: 260,
          ),
              GlowSpec(
                alignment: Alignment.bottomRight,
                offset: Offset(60, 180),
                size: 340,
                opacity: 0.7,
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
                    _GlowLayer(glowColor: palette.glowColor, specs: glowSpecs),
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

  const _GlowLayer({required this.glowColor, required this.specs});

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
                  child: Container(
                    width: spec.size,
                    height: spec.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          glowColor.withOpacity(spec.opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
