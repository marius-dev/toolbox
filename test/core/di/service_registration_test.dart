import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/di/service_locator.dart';
import 'package:project_launcher/core/di/service_registration.dart';
import 'package:project_launcher/core/services/app_icon_resolver.dart';
import 'package:project_launcher/core/services/hotkey_service.dart';
import 'package:project_launcher/core/services/project_metadata_service.dart';
import 'package:project_launcher/core/services/storage_service.dart';
import 'package:project_launcher/core/services/tool_discovery_service.dart';
import 'package:project_launcher/core/services/tray_service.dart';
import 'package:project_launcher/core/services/window_service.dart';
import 'package:project_launcher/core/theme/theme_provider.dart';
import 'package:project_launcher/domain/repositories/project_repository.dart';
import 'package:project_launcher/domain/repositories/workspace_repository.dart';
import 'package:project_launcher/domain/use_cases/project_use_cases.dart';
import 'package:project_launcher/domain/use_cases/tool_use_cases.dart';
import 'package:project_launcher/domain/use_cases/workspace_use_cases.dart';
import 'package:project_launcher/presentation/providers/project_provider.dart';
import 'package:project_launcher/presentation/providers/tools_provider.dart';
import 'package:project_launcher/presentation/providers/workspace_provider.dart';

void main() {
  setUp(() async {
    await resetServiceLocator();
  });

  tearDown(() async {
    await resetServiceLocator();
  });

  group('Service Registration', () {
    test('setupServiceLocator registers all services', () async {
      await setupServiceLocator();

      // Verify all services are registered
      expect(isRegistered<StorageService>(), isTrue);
      expect(isRegistered<WindowService>(), isTrue);
      expect(isRegistered<TrayService>(), isTrue);
      expect(isRegistered<HotkeyService>(), isTrue);
      expect(isRegistered<ToolDiscoveryService>(), isTrue);
      expect(isRegistered<ProjectMetadataService>(), isTrue);
      expect(isRegistered<AppIconResolver>(), isTrue);
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

      final storage = getIt<StorageService>();
      expect(storage, isNotNull);
      expect(storage, isA<StorageService>());
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

      final storage1 = getIt<StorageService>();
      final storage2 = getIt<StorageService>();

      expect(identical(storage1, storage2), isTrue);
    });

    test('dependency chain is resolved correctly', () async {
      await setupServiceLocator();

      // ThemeProvider depends on StorageService
      // This tests that dependencies are injected properly
      final themeProvider = getIt<ThemeProvider>();

      expect(themeProvider, isNotNull);
      // If dependencies weren't properly injected, this would fail
    });
  });
}
