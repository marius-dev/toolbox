import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/di/service_locator.dart';
import 'package:project_launcher/core/di/service_registration.dart';
import 'package:project_launcher/core/services/app_icon_resolver.dart';
import 'package:project_launcher/core/services/hotkey_service.dart';
import 'package:project_launcher/core/services/project_metadata_service.dart';
import 'package:project_launcher/core/services/tool_discovery_service.dart';
import 'package:project_launcher/core/services/tray_service.dart';
import 'package:project_launcher/core/services/window_service.dart';
import 'package:project_launcher/core/theme/theme_provider.dart';
import 'package:project_launcher/domain/repositories/project_repository.dart';
import 'package:project_launcher/domain/repositories/workspace_repository.dart';
import 'package:project_launcher/domain/use_cases/project_use_cases.dart';
import 'package:project_launcher/domain/use_cases/tool_use_cases.dart';
import 'package:project_launcher/domain/use_cases/workspace_use_cases.dart';
import 'package:project_launcher/domain/services/project_launch_service.dart';
import 'package:project_launcher/domain/services/project_metadata_sync_service.dart';
import 'package:project_launcher/presentation/providers/project_provider.dart';
import 'package:project_launcher/presentation/providers/tools_provider.dart';
import 'package:project_launcher/presentation/providers/workspace_provider.dart';

import '../../test_helpers/path_provider_stub.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp(
      'service_registration_test',
    );
    stubPathProvider(path: tempDir.path);
    await resetServiceLocator();
  });

  tearDown(() async {
    await resetServiceLocator();
    resetPathProvider();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Service Registration', () {
    test('setupServiceLocator registers all services', () async {
      await setupServiceLocator();

      // Verify all services are registered
      expect(isRegistered<WindowService>(), isTrue);
      expect(isRegistered<TrayService>(), isTrue);
      expect(isRegistered<HotkeyService>(), isTrue);
      expect(isRegistered<ToolDiscoveryService>(), isTrue);
      expect(isRegistered<ProjectMetadataService>(), isTrue);
      expect(isRegistered<AppIconResolver>(), isTrue);
      expect(isRegistered<ProjectMetadataSyncService>(), isTrue);
      expect(isRegistered<ProjectLaunchService>(), isTrue);
    });

    test('setupServiceLocator registers all repositories', () async {
      await setupServiceLocator();

      expect(isRegistered<ProjectRepository>(), isTrue);
      expect(isRegistered<WorkspaceRepository>(), isTrue);
    });

    test('setupServiceLocator registers all use cases', () async {
      await setupServiceLocator();

      expect(isRegistered<ProjectUseCases>(), isTrue);
      expect(isRegistered<WorkspaceUseCases>(), isTrue);
      expect(isRegistered<ToolUseCases>(), isTrue);
    });

    test('setupServiceLocator registers all providers', () async {
      await setupServiceLocator();

      expect(isRegistered<ProjectProvider>(), isTrue);
      expect(isRegistered<WorkspaceProvider>(), isTrue);
      expect(isRegistered<ToolsProvider>(), isTrue);
    });

    test('setupServiceLocator registers theme provider', () async {
      await setupServiceLocator();

      expect(isRegistered<ThemeProvider>(), isTrue);
    });

    test('services can be retrieved after setup', () async {
      await setupServiceLocator();

      final launchService = getIt<ProjectLaunchService>();
      expect(launchService, isNotNull);
      expect(launchService, isA<ProjectLaunchService>());
    });

    test('repositories depend on services', () async {
      await setupServiceLocator();

      // This should not throw - dependencies should be resolved
      final projectRepo = getIt<ProjectRepository>();
      final workspaceRepo = getIt<WorkspaceRepository>();

      expect(projectRepo, isNotNull);
      expect(workspaceRepo, isNotNull);
    });

    test('use cases depend on repositories', () async {
      await setupServiceLocator();

      // This should not throw - dependencies should be resolved
      final projectUseCases = getIt<ProjectUseCases>();
      final workspaceUseCases = getIt<WorkspaceUseCases>();

      expect(projectUseCases, isNotNull);
      expect(workspaceUseCases, isNotNull);
    });

    test('providers depend on use cases', () async {
      await setupServiceLocator();

      // This should not throw - dependencies should be resolved
      final projectProvider = getIt<ProjectProvider>();
      final workspaceProvider = getIt<WorkspaceProvider>();
      final toolsProvider = getIt<ToolsProvider>();

      expect(projectProvider, isNotNull);
      expect(workspaceProvider, isNotNull);
      expect(toolsProvider, isNotNull);
    });

    test('services are singletons', () async {
      await setupServiceLocator();

      final sync1 = getIt<ProjectMetadataSyncService>();
      final sync2 = getIt<ProjectMetadataSyncService>();

      expect(identical(sync1, sync2), isTrue);
    });

    test('dependency chain is resolved correctly', () async {
      await setupServiceLocator();

      // ThemeProvider depends on ThemeStorageService
      // This tests that dependencies are injected properly
      final themeProvider = getIt<ThemeProvider>();

      expect(themeProvider, isNotNull);
      // If dependencies weren't properly injected, this would fail
    });
  });
}
