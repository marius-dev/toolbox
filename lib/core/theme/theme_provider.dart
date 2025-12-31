import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'glass_style.dart';

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
  GlassStyle _glassStyle = GlassStyle.tinted;
  double _scaleFactor = 1.0;

  static const List<double> scaleOptions = [
    0.7,
    0.8,
    0.9,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  GlassStyle get glassStyle => _glassStyle;
  double get scaleFactor => _scaleFactor;
  double get effectiveScaleFactor => _mapToEffectiveScale(_scaleFactor);
  bool get isDarkMode => _effectiveBrightness == Brightness.dark;
  Brightness get _effectiveBrightness {
    if (_themeMode == ThemeMode.system) {
      return _platformBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
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

  void setGlassStyle(GlassStyle style) {
    if (_glassStyle == style) return;
    _glassStyle = style;
    _saveThemePreferences();
    notifyListeners();
  }

  void setScaleFactor(double scale) {
    final normalized = _normalizeScale(scale);
    if (_scaleFactor == normalized) return;
    _scaleFactor = normalized;
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
    _glassStyle = GlassStyleExtension.fromString(
      prefs['glassStyle'] as String?,
    );
    final storedScale = prefs['scale'];
    final scaleValue = storedScale is num ? storedScale.toDouble() : 1.0;
    _scaleFactor = _normalizeScale(scaleValue);
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
      appScale: _scaleFactor,
      glassStyle: _glassStyle,
    );
  }

  double _normalizeScale(double input) {
    if (scaleOptions.contains(input)) {
      return input;
    }
    for (final option in scaleOptions) {
      if ((input - option).abs() < 0.001) {
        return option;
      }
    }
    return 1.0;
  }

  double _mapToEffectiveScale(double input) {
    if (input <= 1.0) {
      return 1 - (1 - input) * 0.45;
    }
    return 1 + (input - 1) * 0.55;
  }
}
