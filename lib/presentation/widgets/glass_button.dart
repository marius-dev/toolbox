import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/theme_extensions.dart';

class GlassButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final String? tooltip;
  final Color? tintColor;
  final Color? iconColor;

  const GlassButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 32,
    this.tooltip,
    this.tintColor,
    this.iconColor,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.tintColor ?? context.accentColor;
    final baseColor = context.baseSurface;
    final highlight = context.highlightColor(accentColor: accent);
    final baseBorder = context.borderColor(
      opacity: context.isDark ? 0.08 : 0.05,
    );
    final borderColor = widget.tintColor == null
        ? baseBorder
        : context.accentBorderColor(
            accentColor: accent,
            baseBorder: baseBorder,
          );
    final resolvedIconColor =
        widget.iconColor ??
        (widget.tintColor == null
            ? context.iconColor()
            : context.accentWithOpacity(
                accentColor: accent,
                darkOpacity: 0.95,
                lightOpacity: 0.85,
              ));

    final resolvedSize = context.compactValue(widget.size);

    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: GlassTransitions.hoverDuration,
        curve: GlassTransitions.hoverCurve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            child: AnimatedContainer(
              duration: GlassTransitions.hoverDuration,
              curve: GlassTransitions.hoverCurve,
              width: resolvedSize,
              height: resolvedSize,
              decoration: BoxDecoration(
                borderRadius: context.compactRadius(DesignTokens.radiusSm),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [baseColor, Color.alphaBlend(highlight, baseColor)],
                ),
                border: Border.all(
                  color: _isHovered
                      ? borderColor.withValues(alpha: borderColor.a * 1.5)
                      : borderColor,
                  width: 1,
                ),
                boxShadow: [
                  if (context.isDark)
                    BoxShadow(
                      color: ThemeColors.shadowColor(accent, opacity: 0.08),
                      blurRadius: 4, // Further reduced for minimal glow
                      offset: const Offset(0, 2), // Further reduced
                    ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: resolvedIconColor,
                size: context.compactValue(14),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
