import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';

class GlassActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;
  final Color? foregroundColor;

  const GlassActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.primary = false,
    this.danger = false,
    this.foregroundColor,
  });

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final palette = context.glassColors();
    final accent = danger ? context.theme.colorScheme.error : context.accentColor;
    final base = palette.innerColor;

    final gradient = primary
        ? [
            accent.withOpacity(_enabled ? 0.95 : 0.6),
            accent.withOpacity(_enabled ? 0.78 : 0.4),
          ]
        : [
            base,
            Color.alphaBlend(accent.withOpacity(_enabled ? 0.12 : 0.08), base),
          ];

    final borderColor = primary
        ? Colors.white.withOpacity(_enabled ? 0.45 : 0.25)
        : palette.borderColor.withOpacity(_enabled ? 0.9 : 0.6);

    final shadow = primary
        ? [
            BoxShadow(
              color: accent.withOpacity(_enabled ? 0.35 : 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ]
        : [
            BoxShadow(
              color: context.surfaceColor(
                opacity: context.isDark ? 0.22 : 0.08,
              ),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ];

    final defaultIconColor = primary
        ? Colors.white
        : context.theme.iconTheme.color?.withOpacity(_enabled ? 0.9 : 0.5) ??
              Colors.white;
    final iconColor = foregroundColor ?? defaultIconColor;
    final textColor =
        foregroundColor ?? (primary ? Colors.white : defaultIconColor);
    final radius = BorderRadius.circular(10);
    final height = context.compactValue(46);

    return Opacity(
      opacity: _enabled ? 1 : 0.65,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          splashColor: accent.withOpacity(0.12),
          highlightColor: Colors.transparent,
          child: Ink(
            height: height,
            padding: context.compactPadding(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: radius,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: shadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: context.compactValue(18),
                  color: iconColor,
                ),
                SizedBox(width: context.compactValue(10)),
                Text(
                  label,
                  style: context.theme.textTheme.bodyMedium!.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
