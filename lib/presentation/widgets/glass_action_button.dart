import 'package:flutter/material.dart';

import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';

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
    final theme = Theme.of(context);
    final palette = GlassStylePalette.fromContext(
      context,
      style: ThemeProvider.instance.glassStyle,
      accentColor: ThemeProvider.instance.accentColor,
    );
    final accent = danger
        ? theme.colorScheme.error
        : ThemeProvider.instance.accentColor;
    final base = palette.innerColor;
    final isDark = theme.brightness == Brightness.dark;

    final gradient = primary
        ? [
            accent.withOpacity(_enabled ? 0.95 : 0.6),
            accent.withOpacity(_enabled ? 0.78 : 0.4),
          ]
        : [
            base,
            Color.alphaBlend(
              accent.withOpacity(_enabled ? 0.12 : 0.08),
              base,
            ),
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
              color: Colors.black.withOpacity(isDark ? 0.22 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ];

    final defaultIconColor = primary
        ? Colors.white
        : theme.iconTheme.color?.withOpacity(_enabled ? 0.9 : 0.5) ??
            Colors.white;
    final iconColor = foregroundColor ?? defaultIconColor;
    final textColor = foregroundColor ??
        (primary ? Colors.white : defaultIconColor);
    final radius = BorderRadius.circular(10);
    final height = CompactLayout.value(context, 46);

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
            padding: EdgeInsets.symmetric(
              horizontal: CompactLayout.value(context, 16),
            ),
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
                  size: CompactLayout.value(context, 18),
                  color: iconColor,
                ),
                SizedBox(width: CompactLayout.value(context, 10)),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium!.copyWith(
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
