import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/use_cases/project_use_cases.dart';
import '../../domain/use_cases/tool_use_cases.dart';
import '../../domain/use_cases/workspace_use_cases.dart';
import '../../presentation/providers/project_provider.dart';
import '../../presentation/providers/tools_provider.dart';
import '../../presentation/providers/workspace_provider.dart';
import '../services/app_icon_resolver.dart';
import '../services/hotkey_service.dart';
import '../services/project_metadata_service.dart';
import '../services/storage_service.dart';
import '../services/storage/hotkey_storage_service.dart';
import '../services/storage/project_storage_service.dart';
import '../services/storage/theme_storage_service.dart';
import '../services/storage/tool_storage_service.dart';
import '../services/storage/workspace_storage_service.dart';
import '../services/tool_discovery_service.dart';
import '../services/tray_service.dart';
import '../services/window_service.dart';
import '../theme/theme_provider.dart';
import 'service_locator.dart';

/// Registers all application dependencies with the service locator.
///
/// This function should be called once at application startup, before
/// any services are accessed. It registers services, repositories,
/// use cases, and providers in the correct dependency order.
///
/// Example:
/// ```dart
/// void main() async {
///   await setupServiceLocator();
///   runApp(MyApp());
/// }
/// ```
Future<void> setupServiceLocator() async {
  // Register services (no dependencies)
  await _registerServices();

  // Register repositories (depend on services)
  _registerRepositories();

  // Register use cases (depend on repositories and services)
  _registerUseCases();

  // Register providers (depend on use cases)
  _registerProviders();

  // Register theme provider
  _registerTheme();
}

/// Registers all core services.
///
/// Services are registered as lazy singletons, meaning they are only
/// instantiated when first accessed. Dependencies are resolved from the
/// service locator.
Future<void> _registerServices() async {
  // Legacy storage service - kept for backward compatibility
  // TODO: Remove once all consumers are migrated to specialized services
  getIt.registerLazySingleton<StorageService>(() => StorageService());

  // Specialized storage services (no dependencies)
  getIt.registerLazySingleton<ProjectStorageService>(
    () => ProjectStorageService(),
  );
  getIt.registerLazySingleton<WorkspaceStorageService>(
    () => WorkspaceStorageService(),
  );
  getIt.registerLazySingleton<ThemeStorageService>(
    () => ThemeStorageService(),
  );
  getIt.registerLazySingleton<HotkeyStorageService>(
    () => HotkeyStorageService(),
  );
  getIt.registerLazySingleton<ToolStorageService>(
    () => ToolStorageService(),
  );

  // Window service (no dependencies)
  getIt.registerLazySingleton<WindowService>(() => WindowService());

  // System services with dependencies
  getIt.registerLazySingleton<TrayService>(
    () => TrayService(getIt<WindowService>()),
  );
  getIt.registerLazySingleton<HotkeyService>(
    () => HotkeyService(getIt<HotkeyStorageService>(), getIt<WindowService>()),
  );

  // Icon resolver (no dependencies) - must be registered before ToolDiscoveryService
  getIt.registerLazySingleton<AppIconResolver>(() => AppIconResolver());

  // Discovery and metadata services
  getIt.registerLazySingleton<ToolDiscoveryService>(
    () => ToolDiscoveryService(getIt<AppIconResolver>()),
  );
  getIt.registerLazySingleton<ProjectMetadataService>(
    () => ProjectMetadataService(),
  );
}

/// Registers all repositories.
///
/// Repositories depend on services and are registered as lazy singletons.
void _registerRepositories() {
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepository(getIt<ProjectStorageService>()),
  );
  getIt.registerLazySingleton<WorkspaceRepository>(
    () => WorkspaceRepository(getIt<WorkspaceStorageService>()),
  );
}

/// Registers all use cases.
///
/// Use cases encapsulate business logic and depend on repositories
/// and services.
void _registerUseCases() {
  getIt.registerLazySingleton<ProjectUseCases>(
    () => ProjectUseCases(
      getIt<ProjectRepository>(),
      getIt<ProjectMetadataService>(),
      getIt<ToolDiscoveryService>(),
    ),
  );
  getIt.registerLazySingleton<WorkspaceUseCases>(
    () => WorkspaceUseCases(getIt<WorkspaceRepository>()),
  );
  getIt.registerLazySingleton<ToolUseCases>(
    () => ToolUseCases(getIt<ToolDiscoveryService>()),
  );
}

/// Registers all providers (state management).
///
/// Providers are registered as lazy singletons and depend on use cases.
void _registerProviders() {
  getIt.registerLazySingleton<ProjectProvider>(
    () => ProjectProvider(getIt<ProjectUseCases>()),
  );
  getIt.registerLazySingleton<WorkspaceProvider>(
    () => WorkspaceProvider(getIt<WorkspaceUseCases>(), getIt<WorkspaceStorageService>()),
  );
  getIt.registerLazySingleton<ToolsProvider>(
    () => ToolsProvider(getIt<ToolUseCases>(), getIt<ToolStorageService>()),
  );
}

/// Registers the theme provider.
///
/// ThemeProvider is a special case as it's accessed globally and
/// needs to be initialized early.
void _registerTheme() {
  getIt.registerLazySingleton<ThemeProvider>(
    () => ThemeProvider(getIt<ThemeStorageService>()),
  );
}
