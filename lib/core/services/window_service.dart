import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class WindowService {
  static final WindowService _instance = WindowService._internal();
  static WindowService get instance => _instance;

  WindowService._internal();

  Future<void> initialize() async {
    final windowOptions = WindowOptions(
      size: const Size(400, 700),
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
      await show();
      await positionNearTray();
    });
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
      await positionNearTray();
      await show();
    }
  }

  Future<void> positionNearTray() async {
    try {
      final trayBounds = await trayManager.getBounds();
      if (trayBounds == null) {
        await _setDefaultPosition();
        return;
      }

      final windowSize = await windowManager.getSize();
      final x = trayBounds.left + (trayBounds.width - windowSize.width) / 2;
      final y = trayBounds.bottom + 8;
      await windowManager.setPosition(Offset(x, y));
    } catch (_) {
      await _setDefaultPosition();
    }
  }

  Future<void> _setDefaultPosition() async {
    final bounds = await windowManager.getBounds();
    await windowManager.setPosition(Offset(bounds.width - 520, 40));
  }
}
