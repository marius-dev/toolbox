import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/services/storage/theme_storage_service.dart';
import 'package:project_launcher/core/theme/glass_style.dart';

void main() {
  late ThemeStorageService service;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = ThemeStorageService();
    tempDir = await Directory.systemTemp.createTemp('theme_storage_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ThemeStorageService', () {
    test('getThemePreferences returns defaults when no preferences exist', () async {
      final prefs = await service.getThemePreferences();

      expect(prefs['themeMode'], equals('system'));
      expect(prefs['accentColor'], equals(0xFF6366F1));
      expect(prefs['scale'], equals(1.0));
      expect(prefs['glassStyle'], equals('tinted'));
    });

    test('saveThemePreferences and getThemePreferences work correctly', () async {
      await service.saveThemePreferences(
        themeMode: ThemeMode.dark,
        accentColor: 0xFFFF0000,
        appScale: 1.2,
        glassStyle: GlassStyle.clear,
      );

      final prefs = await service.getThemePreferences();

      expect(prefs['themeMode'], equals('dark'));
      expect(prefs['accentColor'], equals(0xFFFF0000));
      expect(prefs['scale'], equals(1.2));
      expect(prefs['glassStyle'], equals('clear'));
    });

    test('supports all ThemeMode values', () async {
      // Test dark
      await service.saveThemePreferences(
        themeMode: ThemeMode.dark,
        accentColor: 0xFF000000,
        appScale: 1.0,
        glassStyle: GlassStyle.tinted,
      );
      var prefs = await service.getThemePreferences();
      expect(prefs['themeMode'], equals('dark'));

      // Test light
      await service.saveThemePreferences(
        themeMode: ThemeMode.light,
        accentColor: 0xFF000000,
        appScale: 1.0,
        glassStyle: GlassStyle.tinted,
      );
      prefs = await service.getThemePreferences();
      expect(prefs['themeMode'], equals('light'));

      // Test system
      await service.saveThemePreferences(
        themeMode: ThemeMode.system,
        accentColor: 0xFF000000,
        appScale: 1.0,
        glassStyle: GlassStyle.tinted,
      );
      prefs = await service.getThemePreferences();
      expect(prefs['themeMode'], equals('system'));
    });

    test('supports all GlassStyle values', () async {
      // Test clear
      await service.saveThemePreferences(
        themeMode: ThemeMode.system,
        accentColor: 0xFF000000,
        appScale: 1.0,
        glassStyle: GlassStyle.clear,
      );
      var prefs = await service.getThemePreferences();
      expect(prefs['glassStyle'], equals('clear'));

      // Test tinted
      await service.saveThemePreferences(
        themeMode: ThemeMode.system,
        accentColor: 0xFF000000,
        appScale: 1.0,
        glassStyle: GlassStyle.tinted,
      );
      prefs = await service.getThemePreferences();
      expect(prefs['glassStyle'], equals('tinted'));
    });

    test('legacy isDark flag is converted to themeMode', () async {
      // Manually write legacy format to preferences
      final prefs = await service.readPreferences();
      prefs['isDark'] = true;
      await service.writePreferences(prefs);

      final loaded = await service.getThemePreferences();
      expect(loaded['themeMode'], equals('dark'));
    });

    test('saves remove legacy isDark flag', () async {
      // Manually write legacy format
      var prefs = await service.readPreferences();
      prefs['isDark'] = true;
      await service.writePreferences(prefs);

      // Save with new format
      await service.saveThemePreferences(
        themeMode: ThemeMode.light,
        accentColor: 0xFF000000,
        appScale: 1.0,
        glassStyle: GlassStyle.tinted,
      );

      // Verify isDark is removed
      prefs = await service.readPreferences();
      expect(prefs.containsKey('isDark'), isFalse);
      expect(prefs['themeMode'], equals('light'));
    });
  });
}
