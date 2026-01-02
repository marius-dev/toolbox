import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/di/service_locator.dart';

void main() {
  setUp(() async {
    // Reset service locator before each test
    await resetServiceLocator();
  });

  tearDown(() async {
    // Clean up after each test
    await resetServiceLocator();
  });

  group('Service Locator', () {
    test('getIt is accessible', () {
      expect(getIt, isNotNull);
    });

    test('locate retrieves registered service', () {
      // Register a test service
      getIt.registerSingleton<String>('test-service');

      // Retrieve using locate helper
      final service = locate<String>();

      expect(service, equals('test-service'));
    });

    test('isRegistered returns true for registered service', () {
      getIt.registerSingleton<String>('test');

      expect(isRegistered<String>(), isTrue);
    });

    test('isRegistered returns false for unregistered service', () {
      expect(isRegistered<String>(), isFalse);
    });

    test('resetServiceLocator clears all services', () async {
      getIt.registerSingleton<String>('test');
      expect(isRegistered<String>(), isTrue);

      await resetServiceLocator();

      expect(isRegistered<String>(), isFalse);
    });

    test('can register multiple services', () {
      getIt.registerSingleton<String>('string-service');
      getIt.registerSingleton<int>(42);

      expect(locate<String>(), equals('string-service'));
      expect(locate<int>(), equals(42));
    });

    test('lazy singleton is not created until first access', () {
      var creationCount = 0;

      getIt.registerLazySingleton<String>(() {
        creationCount++;
        return 'lazy-service';
      });

      // Should not be created yet
      expect(creationCount, equals(0));

      // Access the service
      final service = locate<String>();

      // Should be created now
      expect(creationCount, equals(1));
      expect(service, equals('lazy-service'));

      // Access again - should not create a new instance
      locate<String>();
      expect(creationCount, equals(1)); // Still 1, not 2
    });
  });
}
