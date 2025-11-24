import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  static ThemeProvider get instance => _instance;

  ThemeProvider._internal() {
    _loadThemePreferences();
  }

  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = const Color(0xFF6366F1);

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    _saveThemePreferences();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    _saveThemePreferences();
    notifyListeners();
  }

  Future<void> _loadThemePreferences() async {
    // Load from storage
    final prefs = await StorageService.instance.getThemePreferences();
    _themeMode = prefs['isDark'] == true ? ThemeMode.dark : ThemeMode.light;
    _accentColor = Color(prefs['accentColor'] ?? 0xFF6366F1);
    notifyListeners();
  }

  Future<void> _saveThemePreferences() async {
    await StorageService.instance.saveThemePreferences(
      isDark: _themeMode == ThemeMode.dark,
      accentColor: _accentColor.value,
    );
  }
}
