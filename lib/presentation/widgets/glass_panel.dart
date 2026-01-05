import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/glass_style.dart';
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
  final GlassDepth depth;
  final bool showHighlightLine;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignTokens.space4),
    this.margin,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(DesignTokens.radiusLg),
    ),
    this.duration = DesignTokens.durationMedium,
    this.curve = DesignTokens.curveDefault,
    this.withShadow = true,
    this.backgroundColor,
    this.isTransparent = false,
    this.depth = GlassDepth.primary,
    this.showHighlightLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.glassColors();

    // Get depth-aware values
    final effectiveBlur = palette.blurForDepth(depth);
    final depthColor = palette.surfaceColorForDepth(depth);

    final effectiveColor = isTransparent
        ? Colors.transparent
        : (backgroundColor ?? depthColor);
    final gradient = isTransparent ? null : palette.gradient;
    final border = isTransparent
        ? Border.all(color: Colors.transparent, width: 0)
        : Border.all(color: palette.borderColor);

    Widget mainContainer = AnimatedContainer(
      duration: duration,
      curve: curve,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: withShadow && !isTransparent
            ? GlassShadows.subtle(palette.isDark)
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isTransparent ? 0 : effectiveBlur,
            sigmaY: isTransparent ? 0 : effectiveBlur,
          ),
          child: Container(
            color: effectiveColor,
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    // Add highlight line at top edge for depth effect
    if (showHighlightLine && !isTransparent) {
      final highlightOpacity = palette.highlightLineOpacity;
      return Stack(
        children: [
          mainContainer,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              margin: margin,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: highlightOpacity),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return mainContainer;
  }
}
