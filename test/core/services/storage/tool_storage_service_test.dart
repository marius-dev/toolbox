import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/services/storage/tool_storage_service.dart';

void main() {
  late ToolStorageService service;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = ToolStorageService();
    tempDir = await Directory.systemTemp.createTemp('tool_storage_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ToolStorageService', () {
    test('getDefaultToolId returns null when not set', () async {
      final toolId = await service.getDefaultToolId();
      expect(toolId, isNull);
    });

    test('saveDefaultToolId and getDefaultToolId work correctly', () async {
      await service.saveDefaultToolId('vscode');
      final toolId = await service.getDefaultToolId();
      expect(toolId, equals('vscode'));
    });

    test('saveDefaultToolId with null clears default tool', () async {
      await service.saveDefaultToolId('vscode');
      await service.saveDefaultToolId(null);
      final toolId = await service.getDefaultToolId();
      expect(toolId, isNull);
    });

    test('saveDefaultToolId overwrites existing default tool', () async {
      await service.saveDefaultToolId('vscode');
      await service.saveDefaultToolId('intellij');
      final toolId = await service.getDefaultToolId();
      expect(toolId, equals('intellij'));
    });

    test('getDefaultToolId returns null for empty string', () async {
      // Manually set empty string to test edge case
      final prefs = await service.readPreferences();
      prefs['defaultToolId'] = '';
      await service.writePreferences(prefs);

      final toolId = await service.getDefaultToolId();
      expect(toolId, isNull);
    });
  });
}
