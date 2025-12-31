import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  static final WindowService _instance = WindowService._internal();
  static WindowService get instance => _instance;

  static const Size _baseWindowSize = Size(460, 640);
  static const double _edgePadding = 8;

  WindowService._internal();

  int _autoHideSuppressionCount = 0;

  bool get shouldAutoHideOnBlur => _autoHideSuppressionCount == 0;

  void pushAutoHideSuppression() {
    _autoHideSuppressionCount++;
  }

  void popAutoHideSuppression() {
    if (_autoHideSuppressionCount > 0) {
      _autoHideSuppressionCount--;
    }
  }

  Future<T?> runWithAutoHideSuppressed<T>(
    Future<T?> Function() operation,
  ) async {
    pushAutoHideSuppression();
    try {
      return await operation();
    } finally {
      popAutoHideSuppression();
    }
  }

  Future<void> initialize() async {
    final windowOptions = WindowOptions(
      size: _baseWindowSize,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setHasShadow(false);
      await windowManager.setMovable(false);
      await _applyWindowBounds(_baseWindowSize);
      await _positionTopRight();
      await show();
    });
  }

  Future<void> resizeForScale(double scale) async {
    final scaledSize = _scaledWindowSize(scale);
    await _applyWindowBounds(scaledSize);
    await _positionTopRight();
  }

  Size _scaledWindowSize(double scale) {
    return Size(_baseWindowSize.width * scale, _baseWindowSize.height * scale);
  }

  Future<void> _applyWindowBounds(Size size) async {
    await windowManager.setResizable(false);
    await windowManager.setSize(size);
    await windowManager.setMinimumSize(size);
    await windowManager.setMaximumSize(size);
  }

  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hide() async {
    await windowManager.hide();
  }

  Future<void> toggle() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await hide();
    } else {
      await _positionTopRight();
      await show();
    }
  }

  Future<void> _positionTopRight() async {
    await windowManager.setAlignment(Alignment.topRight);

    if (_edgePadding <= 0) return;

    final alignedPosition = await windowManager.getPosition();
    await windowManager.setPosition(
      Offset(
        alignedPosition.dx - _edgePadding,
        alignedPosition.dy + _edgePadding,
      ),
    );
  }
}
