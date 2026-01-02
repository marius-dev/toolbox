import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/services/storage/workspace_storage_service.dart';

void main() {
  late WorkspaceStorageService service;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    service = WorkspaceStorageService();
    tempDir = await Directory.systemTemp.createTemp('workspace_storage_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WorkspaceStorageService', () {
    test('loadWorkspaces returns empty list when file does not exist', () async {
      final workspaces = await service.loadWorkspaces();
      expect(workspaces, isEmpty);
    });

    test('saveWorkspaces and loadWorkspaces work correctly', () async {
      final testWorkspaces = [
        {'id': '1', 'name': 'Workspace 1', 'scanPaths': []},
        {'id': '2', 'name': 'Workspace 2', 'scanPaths': []},
      ];

      await service.saveWorkspaces(testWorkspaces);
      final loaded = await service.loadWorkspaces();

      expect(loaded.length, equals(2));
      expect(loaded[0]['id'], equals('1'));
      expect(loaded[0]['name'], equals('Workspace 1'));
      expect(loaded[1]['id'], equals('2'));
      expect(loaded[1]['name'], equals('Workspace 2'));
    });

    test('getSelectedWorkspaceId returns null when not set', () async {
      final id = await service.getSelectedWorkspaceId();
      expect(id, isNull);
    });

    test('saveSelectedWorkspaceId and getSelectedWorkspaceId work correctly', () async {
      await service.saveSelectedWorkspaceId('workspace-123');
      final id = await service.getSelectedWorkspaceId();
      expect(id, equals('workspace-123'));
    });

    test('saveSelectedWorkspaceId with null clears selection', () async {
      await service.saveSelectedWorkspaceId('workspace-123');
      await service.saveSelectedWorkspaceId(null);
      final id = await service.getSelectedWorkspaceId();
      expect(id, isNull);
    });

    test('saveSelectedWorkspaceId with empty string clears selection', () async {
      await service.saveSelectedWorkspaceId('workspace-123');
      await service.saveSelectedWorkspaceId('');
      final id = await service.getSelectedWorkspaceId();
      expect(id, isNull);
    });
  });
}
