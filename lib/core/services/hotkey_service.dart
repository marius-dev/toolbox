import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:project_launcher/core/services/storage_service.dart';
import 'package:project_launcher/core/services/window_service.dart';

class HotkeyService extends ChangeNotifier {
  static final HotkeyService _instance = HotkeyService._internal();
  static HotkeyService get instance => _instance;

  HotkeyService._internal();

  HotKey? _launcherHotKey;

  HotKey? get currentHotKey => _launcherHotKey;

  Future<void> initialize() async {
    try {
      final saved = await StorageService.instance.getHotkeyPreference();
      if (saved != null) {
        _launcherHotKey = HotKey.fromJson(saved)..scope = HotKeyScope.system;
        await _registerHotkey(_launcherHotKey!);
      }
    } catch (e) {
      debugPrint('Hotkey load error: $e');
    }
  }

  Future<void> setHotkey(HotKey? hotKey) async {
    await _unregisterCurrent();
    _launcherHotKey = hotKey;

    if (hotKey != null) {
      _launcherHotKey!.scope = HotKeyScope.system;
      await _registerHotkey(_launcherHotKey!);
      await StorageService.instance.saveHotkeyPreference(
        _launcherHotKey!.toJson(),
      );
    } else {
      await StorageService.instance.saveHotkeyPreference(null);
    }

    notifyListeners();
  }

  Future<void> _registerHotkey(HotKey hotKey) async {
    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) => WindowService.instance.toggle(),
      );
    } catch (e) {
      debugPrint('Hotkey registration error: $e');
    }
  }

  Future<void> _unregisterCurrent() async {
    if (_launcherHotKey == null) return;
    try {
      await hotKeyManager.unregister(_launcherHotKey!);
    } catch (e) {
      debugPrint('Hotkey unregister error: $e');
    }
  }
}
