import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_provider.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final Duration duration;
  final Curve curve;
  final bool withShadow;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeInOut,
    this.withShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = GlassStylePalette.fromContext(
      context,
      style: ThemeProvider.instance.glassStyle,
      accentColor: ThemeProvider.instance.accentColor,
    );

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      margin: margin,
      decoration: BoxDecoration(
        gradient: palette.gradient,
        borderRadius: borderRadius,
        border: Border.all(color: palette.borderColor),
        boxShadow: withShadow ? palette.shadow : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: palette.blurSigma,
            sigmaY: palette.blurSigma,
          ),
          child: Container(
            color: palette.innerColor,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
