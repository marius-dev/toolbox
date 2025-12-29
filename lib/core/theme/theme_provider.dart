import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  static final ThemeProvider _instance = ThemeProvider._internal();
  static ThemeProvider get instance => _instance;

  ThemeProvider._internal() {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    binding.addObserver(this);
    _platformBrightness = binding.platformDispatcher.platformBrightness;
    _loadThemePreferences();
  }

  ThemeMode _themeMode = ThemeMode.system;
  Brightness _platformBrightness = Brightness.dark;
  Color _accentColor = const Color(0xFF6366F1);

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get isDarkMode => _effectiveBrightness == Brightness.dark;
  Brightness get _effectiveBrightness {
    if (_themeMode == ThemeMode.system) {
      return _platformBrightness;
    }
    return _themeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _saveThemePreferences();
    notifyListeners();
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _saveThemePreferences();
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (brightness == _platformBrightness) return;

    _platformBrightness = brightness;
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  Future<void> _loadThemePreferences() async {
    // Load from storage
    final prefs = await StorageService.instance.getThemePreferences();
    _themeMode = _themeModeFromString(prefs['themeMode'] as String?);
    _accentColor = Color(prefs['accentColor'] ?? 0xFF6366F1);
    notifyListeners();
  }

  ThemeMode _themeModeFromString(String? stored) {
    switch (stored) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _saveThemePreferences() async {
    await StorageService.instance.saveThemePreferences(
      themeMode: _themeMode,
      accentColor: _accentColor.value,
    );
  }
}
