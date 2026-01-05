import 'package:flutter/widgets.dart';

/// Provides consistent scaling for compact layouts based on the current window width.
class CompactLayout {
  static const double _baseWidth = 520;
  static const double _minScale = 0.72;
  static const double _maxScale = 1.0;

  /// Returns a scale factor between `_minScale` and `_maxScale`, clamped
  /// relative to the `_baseWidth`.
  static double scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width.isInfinite || width <= 0) {
      return _maxScale;
    }

    return (width / _baseWidth).clamp(_minScale, _maxScale);
  }

  static double value(BuildContext context, double size) =>
      size * scale(context);

  static EdgeInsetsGeometry symmetric(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    final factor = scale(context);

    return EdgeInsets.symmetric(
      horizontal: horizontal * factor,
      vertical: vertical * factor,
    );
  }

  static EdgeInsetsGeometry only(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final factor = scale(context);

    return EdgeInsets.only(
      left: left * factor,
      top: top * factor,
      right: right * factor,
      bottom: bottom * factor,
    );
  }
}
