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
  double _appliedScale = ThemeProvider.instance.effectiveScaleFactor;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final scale = ThemeProvider.instance.effectiveScaleFactor;
        if (_appliedScale != scale) {
          _appliedScale = scale;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WindowService.instance.resizeForScale(scale);
          });
        }
        return MaterialApp(
          title: 'Project Launcher',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeProvider.instance.themeMode,
          builder: (context, child) =>
              _buildScaledContent(context, child, scale),
          home: const LauncherScreen(),
        );
      },
    );
  }

  Widget _buildScaledContent(
    BuildContext context,
    Widget? child,
    double scale,
  ) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaleFactor: scale,
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
