import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'core/di/service_locator.dart';
import 'core/di/service_registration.dart';
import 'core/services/hotkey_service.dart';
import 'core/services/tray_service.dart';
import 'core/services/window_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/screens/launcher_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependency injection
  await setupServiceLocator();

  // Initialize services
  await _initializeServices();

  runApp(const ProjectLauncherApp());
}

Future<void> _initializeServices() async {
  await windowManager.ensureInitialized();
  await getIt<WindowService>().initialize();
  await getIt<TrayService>().initialize();
  await getIt<HotkeyService>().initialize();
}

class ProjectLauncherApp extends StatefulWidget {
  const ProjectLauncherApp({super.key});

  @override
  State<ProjectLauncherApp> createState() => _ProjectLauncherAppState();
}

class _ProjectLauncherAppState extends State<ProjectLauncherApp> {
  late final ThemeProvider _themeProvider;
  late final WindowService _windowService;
  late double _appliedScale;

  @override
  void initState() {
    super.initState();
    _themeProvider = getIt<ThemeProvider>();
    _windowService = getIt<WindowService>();
    _appliedScale = _themeProvider.effectiveScaleFactor;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, _) {
        final scale = _themeProvider.effectiveScaleFactor;
        if (_appliedScale != scale) {
          _appliedScale = scale;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _windowService.resizeForScale(scale);
          });
        }
        return MaterialApp(
          title: 'Project Launcher',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeProvider.themeMode,
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
      data: mediaQuery.copyWith(textScaleFactor: scale),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
