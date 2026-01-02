import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final Duration duration;
  final Curve curve;
  final bool withShadow;
  final Color? backgroundColor;
  final bool isTransparent;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeInOut,
    this.withShadow = true,
    this.backgroundColor,
    this.isTransparent = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.glassColors();
    final effectiveColor = isTransparent
        ? Colors.transparent
        : (backgroundColor ?? palette.innerColor);
    final gradient = isTransparent ? null : palette.gradient;
    final border = isTransparent
        ? Border.all(color: Colors.transparent, width: 0)
        : Border.all(color: palette.borderColor);

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: withShadow && !isTransparent ? palette.shadow : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isTransparent ? 0 : palette.blurSigma,
            sigmaY: isTransparent ? 0 : palette.blurSigma,
          ),
          child: Container(
            color: effectiveColor,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
