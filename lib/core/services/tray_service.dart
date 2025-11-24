import 'dart:io';

import 'package:flutter/material.dart';
import 'package:project_launcher/core/services/window_service.dart';
import 'package:tray_manager/tray_manager.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  static TrayService get instance => _instance;

  TrayService._internal();

  Future<void> initialize() async {
    trayManager.addListener(this);

    try {
      await trayManager.setIcon(
        Platform.isMacOS ? 'assets/icon.png' : 'assets/icon.png',
      );
      await trayManager.setToolTip('Project Launcher');

      final menu = Menu(
        items: [
          MenuItem(key: 'show', label: 'Show Launcher'),
          MenuItem.separator(),
          MenuItem(key: 'exit', label: 'Exit'),
        ],
      );
      await trayManager.setContextMenu(menu);
    } catch (e) {
      debugPrint('Tray init error: $e');
    }
  }

  @override
  void onTrayIconMouseDown() {
    WindowService.instance.toggle();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      WindowService.instance.toggle();
    } else if (menuItem.key == 'exit') {
      exit(0);
    }
  }
}
