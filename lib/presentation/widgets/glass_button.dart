import 'package:flutter/material.dart';

import '../../core/theme/theme_colors.dart';
import '../../core/theme/theme_extensions.dart';

class GlassButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final accent = tintColor ?? context.accentColor;
    final baseColor = context.baseSurface;
    final highlight = context.highlightColor(accentColor: accent);
    final baseBorder = context.borderColor(opacity: context.isDark ? 0.1 : 0.08);
    final borderColor = tintColor == null
        ? baseBorder
        : context.accentBorderColor(accentColor: accent, baseBorder: baseBorder);
    final resolvedIconColor = iconColor ??
        (tintColor == null
            ? context.iconColor()
            : context.accentWithOpacity(
                accentColor: accent,
                darkOpacity: 0.95,
                lightOpacity: 0.85,
              ));

    final resolvedSize = context.compactValue(size);
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: resolvedSize,
          height: resolvedSize,
          decoration: BoxDecoration(
            borderRadius: context.compactRadius(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, Color.alphaBlend(highlight, baseColor)],
            ),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              if (context.isDark)
                BoxShadow(
                  color: ThemeColors.shadowColor(accent),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Icon(
            icon,
            color: resolvedIconColor,
            size: context.compactValue(14),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
