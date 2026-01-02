import 'package:get_it/get_it.dart';

/// Global service locator instance.
///
/// This is the single GetIt instance used throughout the application.
/// All services, repositories, and use cases are registered here.
final getIt = GetIt.instance;

/// Type-safe wrapper for locating services.
///
/// This is a convenience function that provides a cleaner syntax
/// for retrieving dependencies from the service locator.
///
/// Example:
/// ```dart
/// final storage = locate<StorageService>();
/// ```
T locate<T extends Object>() => getIt<T>();

/// Checks if a service is registered.
///
/// Useful for conditional logic or testing.
bool isRegistered<T extends Object>() => getIt.isRegistered<T>();

/// Resets all registered services (for testing).
///
/// WARNING: Only use this in tests. Do not call in production code.
Future<void> resetServiceLocator() => getIt.reset();
