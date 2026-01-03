import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

class ListingItemContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final bool isActive;
  final bool isDisabled;
  final bool isHovering;

  ListingItemContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
    this.margin,
    BorderRadiusGeometry? borderRadius,
    this.isActive = false,
    this.isDisabled = false,
    this.isHovering = false,
  }) : borderRadius = borderRadius ?? BorderRadius.circular(12);

  @override
  Widget build(BuildContext context) {
    final visuals = ListingItemVisuals.resolve(
      context,
      isActive: isActive,
      isDisabled: isDisabled,
      isHovering: isHovering,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: visuals.backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: visuals.borderColor, width: 1),
        boxShadow: visuals.shadow,
      ),
      child: child,
    );
  }
}

class ListingItemVisuals {
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow>? shadow;

  const ListingItemVisuals({
    required this.backgroundColor,
    required this.borderColor,
    this.shadow,
  });

  factory ListingItemVisuals.resolve(
    BuildContext context, {
    bool isActive = false,
    bool isDisabled = false,
    bool isHovering = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = context.accentColor;
    final surface = theme.colorScheme.surface;

    final baseOverlay = isDark
        ? Colors.white.withOpacity(0.03)
        : Colors.black.withOpacity(0.02);
    final hoverOverlay = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
    final activeOverlay = accentColor.withOpacity(isDark ? 0.28 : 0.15);
    final disabledOverlay = isDark
        ? Colors.black.withOpacity(0.25)
        : Colors.white.withOpacity(0.25);

    Color background = Color.alphaBlend(baseOverlay, surface);

    if (isActive) {
      background = Color.alphaBlend(activeOverlay, background);
    }

    if (isHovering && !isDisabled && !isActive) {
      background = Color.alphaBlend(hoverOverlay, background);
    }

    if (isDisabled) {
      background = Color.alphaBlend(disabledOverlay, background);
    }

    final borderBase = theme.colorScheme.onSurface.withOpacity(
      isDark ? 0.14 : 0.08,
    );

    final borderColor = isActive
        ? accentColor.withOpacity(0.75)
        : isHovering && !isDisabled
        ? accentColor.withOpacity(isDark ? 0.25 : 0.18)
        : borderBase;

    final shadowOpacity = isActive
        ? (isDark ? 0.25 : 0.16)
        : (isHovering && !isDisabled ? 0.08 : 0.0);
    final shadow = shadowOpacity > 0
        ? [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.black).withOpacity(
                shadowOpacity,
              ),
              blurRadius: isActive ? 24 : 12,
              offset: Offset(0, isActive ? 12 : 6),
            ),
          ]
        : null;

    return ListingItemVisuals(
      backgroundColor: background,
      borderColor: borderColor,
      shadow: shadow,
    );
  }
}
