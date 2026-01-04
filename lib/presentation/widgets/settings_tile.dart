import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_extensions.dart';

class SettingsTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;

  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.glassColors();
    final isDark = context.isDark;

    // Glass-based background with hover state
    final backgroundColor = _isHovered
        ? Color.alphaBlend(
            Colors.white.withValues(alpha: isDark ? 0.04 : 0.6),
            palette.innerColor,
          )
        : palette.innerColor;

    final borderColor = _isHovered
        ? palette.borderColor.withValues(alpha: palette.borderColor.a * 1.2)
        : palette.borderColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: GlassTransitions.hoverDuration,
        curve: GlassTransitions.hoverCurve,
        margin: context.compactPaddingOnly(bottom: DesignTokens.space2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: GlassShadows.subtle(isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignTokens.blurSubtle,
              sigmaY: DesignTokens.blurSubtle,
            ),
            child: Padding(
              padding: EdgeInsets.all(
                context.compactValue(DesignTokens.space3),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      context.compactValue(DesignTokens.space1 + 2),
                    ),
                    decoration: BoxDecoration(
                      // Subtle neutral background instead of accent tint
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(
                        context.compactValue(DesignTokens.radiusSm),
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: Theme.of(context).iconTheme.color,
                      size: DesignTokens.iconLg,
                    ),
                  ),
                  SizedBox(width: context.compactValue(DesignTokens.space3)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: context.compactValue(2)),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: context.compactValue(DesignTokens.space3)),
                  widget.trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
