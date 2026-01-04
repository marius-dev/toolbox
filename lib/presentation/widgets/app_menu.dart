import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_extensions.dart';

class AppMenuStyle {
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle textStyle;
  final TextStyle mutedTextStyle;
  final ShapeBorder shape;
  final Offset offset;
  final double elevation;

  const AppMenuStyle._({
    required this.backgroundColor,
    required this.borderColor,
    required this.textStyle,
    required this.mutedTextStyle,
    required this.shape,
    required this.offset,
    required this.elevation,
  });

  factory AppMenuStyle.of(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseTextStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 12);
    final baseTextColor = baseTextStyle.color ?? colorScheme.onSurface;

    // Solid border for clear separation
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    // Solid opaque backgrounds - no transparency
    final backgroundColor = isDark
        ? const Color(0xFF1C1C1E) // Dark solid gray (iOS-like)
        : const Color(0xFFFAFAFA); // Light solid off-white

    return AppMenuStyle._(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      textStyle: baseTextStyle.copyWith(color: baseTextColor),
      mutedTextStyle: baseTextStyle.copyWith(
        color: baseTextColor.withValues(alpha: 0.4),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        side: BorderSide(color: borderColor, width: 1),
      ),
      offset: const Offset(0, 8),
      elevation: isDark ? 12 : 8, // Proper shadow for depth
    );
  }

  Color resolveTextColor(bool enabled) =>
      enabled ? textStyle.color! : mutedTextStyle.color!;
}

class AppMenuButton<T> extends StatefulWidget {
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final Widget? child;
  final Icon? icon;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;
  final Offset? offset;
  final bool enabled;
  final double? elevation;
  final ShapeBorder? shape;
  final Color? color;
  final PopupMenuPosition position;
  final bool openOnHover;

  const AppMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.child,
    this.icon,
    this.tooltip,
    this.padding,
    this.offset,
    this.enabled = true,
    this.elevation,
    this.shape,
    this.color,
    this.position = PopupMenuPosition.over,
    this.openOnHover = false,
  });

  @override
  State<AppMenuButton<T>> createState() => _AppMenuButtonState<T>();
}

class _AppMenuButtonState<T> extends State<AppMenuButton<T>> {
  final GlobalKey<PopupMenuButtonState<T>> _menuKey =
      GlobalKey<PopupMenuButtonState<T>>();
  bool _menuOpen = false;

  void _handleHoverEnter(PointerEnterEvent event) {
    if (!widget.openOnHover || !widget.enabled || _menuOpen) return;
    _menuOpen = true;
    _menuKey.currentState?.showButtonMenu();
  }

  void _handleSelected(T value) {
    _resetMenuState();
    widget.onSelected?.call(value);
  }

  void _handleCanceled() {
    _resetMenuState();
  }

  void _resetMenuState() {
    _menuOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final menuStyle = AppMenuStyle.of(context);

    final menuButton = PopupMenuButton<T>(
      key: _menuKey,
      itemBuilder: widget.itemBuilder,
      onSelected: _handleSelected,
      onCanceled: _handleCanceled,
      tooltip: widget.tooltip,
      padding: widget.padding ?? const EdgeInsets.all(DesignTokens.space2),
      offset: widget.offset ?? menuStyle.offset,
      color: widget.color ?? menuStyle.backgroundColor,
      shape: widget.shape ?? menuStyle.shape,
      elevation: widget.elevation ?? menuStyle.elevation,
      enabled: widget.enabled,
      position: widget.position,
      icon: widget.icon,
      child: widget.child,
    );

    if (!widget.openOnHover) {
      return menuButton;
    }

    return MouseRegion(
      onEnter: _handleHoverEnter,
      // onExit: _handleHoverExit,
      child: menuButton,
    );
  }
}

/// Pill-styled menu item that matches the design system
class PillMenuItem<T> extends PopupMenuItem<T> {
  PillMenuItem({
    super.key,
    super.value,
    super.onTap,
    super.enabled,
    required Widget child,
  }) : super(
         padding: const EdgeInsets.symmetric(
           horizontal: DesignTokens.space2,
           vertical: DesignTokens.space1,
         ),
         child: _PillMenuItemContent(child: child),
       );
}

class _PillMenuItemContent extends StatefulWidget {
  final Widget child;

  const _PillMenuItemContent({required this.child});

  @override
  State<_PillMenuItemContent> createState() => _PillMenuItemContentState();
}

class _PillMenuItemContentState extends State<_PillMenuItemContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final hoverColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space2,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? hoverColor : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        child: widget.child,
      ),
    );
  }
}
