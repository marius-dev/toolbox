import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/services/storage/project_storage_service.dart';

import '../../../test_helpers/path_provider_stub.dart';

void main() {
  late ProjectStorageService service;
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('project_storage_test');
    stubPathProvider(path: tempDir.path);
    service = ProjectStorageService();
  });

  tearDown(() async {
    resetPathProvider();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ProjectStorageService', () {
    test('loadProjects returns empty list when file does not exist', () async {
      final projects = await service.loadProjects();
      expect(projects, isEmpty);
    });

    test('saveProjects and loadProjects work correctly', () async {
      final testProjects = [
        {'id': '1', 'name': 'Project 1', 'path': '/path/1'},
        {'id': '2', 'name': 'Project 2', 'path': '/path/2'},
      ];

      await service.saveProjects(testProjects);
      final loaded = await service.loadProjects();

      expect(loaded.length, equals(2));
      expect(loaded[0]['id'], equals('1'));
      expect(loaded[0]['name'], equals('Project 1'));
      expect(loaded[1]['id'], equals('2'));
      expect(loaded[1]['name'], equals('Project 2'));
    });

    test('saveProjects overwrites existing projects', () async {
      final firstProjects = [
        {'id': '1', 'name': 'First', 'path': '/first'},
      ];
      final secondProjects = [
        {'id': '2', 'name': 'Second', 'path': '/second'},
      ];

      await service.saveProjects(firstProjects);
      await service.saveProjects(secondProjects);
      final loaded = await service.loadProjects();

      expect(loaded.length, equals(1));
      expect(loaded[0]['id'], equals('2'));
      expect(loaded[0]['name'], equals('Second'));
    });
  });
}
