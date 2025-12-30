import 'package:flutter/material.dart';

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
    final borderColor = colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.06);

    return AppMenuStyle._(
      backgroundColor:
          isDark ? Colors.black.withOpacity(0.84) : colorScheme.surface,
      borderColor: borderColor,
      textStyle: baseTextStyle.copyWith(color: baseTextColor),
      mutedTextStyle:
          baseTextStyle.copyWith(color: baseTextColor.withOpacity(0.4)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      offset: const Offset(0, 10),
      elevation: 0,
    );
  }

  Color resolveTextColor(bool enabled) =>
      enabled ? textStyle.color! : mutedTextStyle.color!;
}

class AppMenuButton<T> extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final menuStyle = AppMenuStyle.of(context);

    return PopupMenuButton<T>(
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      tooltip: tooltip,
      padding: padding ?? const EdgeInsets.all(8),
      offset: offset ?? menuStyle.offset,
      color: color ?? menuStyle.backgroundColor,
      shape: shape ?? menuStyle.shape,
      elevation: elevation ?? menuStyle.elevation,
      enabled: enabled,
      position: position,
      icon: icon,
      child: child,
    );
  }
}
