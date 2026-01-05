import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
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
    final isDark = context.isDark;
    final accent = danger
        ? context.theme.colorScheme.error
        : context.accentColor;
    final base = palette.innerColor;

    // Subtler gradients for modern minimal aesthetic
    // In dark mode, use neutral colors for non-primary buttons
    final gradient = primary
        ? [
            accent.withValues(alpha: _enabled ? 0.90 : 0.55),
            accent.withValues(alpha: _enabled ? 0.70 : 0.35),
          ]
        : isDark
        ? [
            Colors.white.withValues(alpha: _enabled ? 0.08 : 0.04),
            Colors.white.withValues(alpha: _enabled ? 0.05 : 0.02),
          ]
        : [
            base,
            Color.alphaBlend(
              accent.withValues(alpha: _enabled ? 0.08 : 0.05),
              base,
            ),
          ];

    final borderColor = primary
        ? Colors.white.withValues(alpha: _enabled ? 0.35 : 0.18)
        : palette.borderColor.withValues(
            alpha: palette.borderColor.a * (_enabled ? 0.85 : 0.55),
          );

    // Reduced shadows for minimal look
    final shadow = primary
        ? [
            BoxShadow(
              color: accent.withValues(alpha: _enabled ? 0.15 : 0.08),
              blurRadius: 10, // Further reduced
              offset: const Offset(0, 4), // Further reduced
            ),
          ]
        : [
            BoxShadow(
              color: context.surfaceColor(
                opacity: context.isDark ? 0.08 : 0.04,
              ),
              blurRadius: 6, // Further reduced
              offset: const Offset(0, 3), // Further reduced
            ),
          ];

    final defaultIconColor = primary
        ? Colors.white
        : context.theme.iconTheme.color?.withValues(
                alpha: _enabled ? 0.9 : 0.5,
              ) ??
              Colors.white;
    final iconColor = foregroundColor ?? defaultIconColor;
    final textColor =
        foregroundColor ?? (primary ? Colors.white : defaultIconColor);
    final radius = BorderRadius.circular(DesignTokens.radiusSm);
    final height = context.compactValue(DesignTokens.buttonHeight + 8);

    return Opacity(
      opacity: _enabled ? 1 : 0.65,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          splashColor: accent.withValues(alpha: 0.10),
          highlightColor: Colors.transparent,
          child: Ink(
            height: height,
            padding: context.compactPadding(horizontal: DesignTokens.space4),
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
                  size: context.compactValue(DesignTokens.iconLg),
                  color: iconColor,
                ),
                SizedBox(width: context.compactValue(DesignTokens.space3)),
                Text(
                  label,
                  style: context.theme.textTheme.bodyMedium!.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
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
