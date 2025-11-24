import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'core/services/window_service.dart';
import 'core/services/tray_service.dart';
import 'core/services/hotkey_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/screens/launcher_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await _initializeServices();

  runApp(const ProjectLauncherApp());
}

Future<void> _initializeServices() async {
  await windowManager.ensureInitialized();
  await WindowService.instance.initialize();
  await TrayService.instance.initialize();
  await HotkeyService.instance.initialize();
}

class ProjectLauncherApp extends StatefulWidget {
  const ProjectLauncherApp({super.key});

  @override
  State<ProjectLauncherApp> createState() => _ProjectLauncherAppState();
}

class _ProjectLauncherAppState extends State<ProjectLauncherApp> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Project Launcher',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeProvider.instance.themeMode,
          home: const LauncherScreen(),
        );
      },
    );
  }
}
