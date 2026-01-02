import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/services/storage/hotkey_storage_service.dart';

import '../../../test_helpers/path_provider_stub.dart';

void main() {
  late HotkeyStorageService service;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('hotkey_storage_test');
    stubPathProvider(path: tempDir.path);
    service = HotkeyStorageService();
  });

  tearDown(() async {
    resetPathProvider();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HotkeyStorageService', () {
    test('getHotkeyPreference returns null when not set', () async {
      final hotkey = await service.getHotkeyPreference();
      expect(hotkey, isNull);
    });

    test(
      'saveHotkeyPreference and getHotkeyPreference work correctly',
      () async {
        final testHotkey = {
          'keyCode': 'space',
          'modifiers': ['command', 'shift'],
        };

        await service.saveHotkeyPreference(testHotkey);
        final loaded = await service.getHotkeyPreference();

        expect(loaded, isNotNull);
        expect(loaded!['keyCode'], equals('space'));
        expect(loaded['modifiers'], equals(['command', 'shift']));
      },
    );

    test('saveHotkeyPreference with null clears hotkey', () async {
      final testHotkey = {
        'keyCode': 'space',
        'modifiers': ['command'],
      };

      await service.saveHotkeyPreference(testHotkey);
      await service.saveHotkeyPreference(null);
      final loaded = await service.getHotkeyPreference();

      expect(loaded, isNull);
    });

    test('saveHotkeyPreference overwrites existing hotkey', () async {
      final firstHotkey = {
        'keyCode': 'space',
        'modifiers': ['command'],
      };
      final secondHotkey = {
        'keyCode': 'enter',
        'modifiers': ['shift'],
      };

      await service.saveHotkeyPreference(firstHotkey);
      await service.saveHotkeyPreference(secondHotkey);
      final loaded = await service.getHotkeyPreference();

      expect(loaded!['keyCode'], equals('enter'));
      expect(loaded['modifiers'], equals(['shift']));
    });
  });
}
