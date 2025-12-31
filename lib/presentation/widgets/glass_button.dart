import 'package:flutter/material.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = tintColor ?? ThemeProvider.instance.accentColor;
    final baseColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.02);
    final highlight = isDark
        ? accent.withOpacity(0.18)
        : accent.withOpacity(0.08);
    final baseBorder = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.08);
    final borderColor = tintColor == null
        ? baseBorder
        : Color.alphaBlend(
            accent.withOpacity(isDark ? 0.25 : 0.18),
            baseBorder,
          );
    final defaultIconColor = isDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black.withOpacity(0.65);
    final resolvedIconColor =
        iconColor ??
        (tintColor == null
            ? defaultIconColor
            : accent.withOpacity(isDark ? 0.95 : 0.85));

    final resolvedSize = CompactLayout.value(context, size);
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: resolvedSize,
          height: resolvedSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              CompactLayout.value(context, 10),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, Color.alphaBlend(highlight, baseColor)],
            ),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              if (isDark)
                BoxShadow(
                  color: accent.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Icon(
            icon,
            color: resolvedIconColor,
            size: CompactLayout.value(context, 14),
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
