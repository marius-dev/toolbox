// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_launcher/core/di/service_locator.dart';
import 'package:project_launcher/core/di/service_registration.dart';
import 'package:project_launcher/main.dart';

import 'test_helpers/path_provider_stub.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('widget_test_path');
    stubPathProvider(path: tempDir.path);
    await resetServiceLocator();
    await setupServiceLocator();
  });

  tearDown(() async {
    await resetServiceLocator();
    resetPathProvider();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Launcher renders the header with tabs', (tester) async {
    await tester.pumpWidget(const ProjectLauncherApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
  });
}
