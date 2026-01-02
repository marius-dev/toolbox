import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Provides a simple stub for path_provider in widget tests.
const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Stubs `getApplicationDocumentsDirectory` to return [path].
void stubPathProvider({required String path}) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_pathProviderChannel, (methodCall) async {
    if (methodCall.method == 'getApplicationDocumentsDirectory') {
      return path;
    }
    return null;
  });
}

/// Restores the default handler for the path_provider channel.
void resetPathProvider() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_pathProviderChannel, null);
}
