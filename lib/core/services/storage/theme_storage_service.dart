import 'package:flutter/material.dart';

import 'base_storage_service.dart';
import 'storage_keys.dart';

/// Storage service responsible for theme preferences.
///
/// This service follows the Single Responsibility Principle by handling
/// only theme-related preferences (mode, accent color, scale, glass style).
class ThemeStorageService extends BaseStorageService {
  /// Gets all theme preferences from storage.
  ///
  /// Returns a map containing themeMode, accentColor, scale, and glassStyle.
  /// Provides sensible defaults if preferences haven't been saved.
  Future<Map<String, dynamic>> getThemePreferences() async {
    final prefs = await readPreferences();
    String? themeMode = prefs[StorageKeys.themeMode];

    // Legacy support for the old isDark flag
    if (themeMode == null && prefs.containsKey(StorageKeys.isDark)) {
      themeMode = prefs[StorageKeys.isDark] == true ? 'dark' : 'light';
    }

    double scale = 1.0;
    final storedScale = prefs[StorageKeys.scale];
    if (storedScale is num) {
      scale = storedScale.toDouble();
    }

    // Set default glass style if not present
    if (!prefs.containsKey(StorageKeys.glassStyle)) {
      prefs[StorageKeys.glassStyle] = 'tinted';
      await writePreferences(prefs);
    }

    return {
      StorageKeys.themeMode: themeMode ?? 'system',
      StorageKeys.accentColor: prefs[StorageKeys.accentColor] ?? 0xFF6366F1,
      StorageKeys.scale: scale,
      StorageKeys.glassStyle: prefs[StorageKeys.glassStyle] ?? 'tinted',
    };
  }

  /// Saves theme preferences to storage.
  ///
  /// All parameters are required to ensure consistency.
  Future<void> saveThemePreferences({
    required ThemeMode themeMode,
    required int accentColor,
    required double appScale,
  }) async {
    final prefs = await readPreferences();
    prefs[StorageKeys.themeMode] = _themeModeToString(themeMode);
    prefs.remove(StorageKeys.isDark); // Remove legacy key
    prefs[StorageKeys.accentColor] = accentColor;
    prefs[StorageKeys.scale] = appScale;
    await writePreferences(prefs);
  }

  /// Converts ThemeMode enum to string for storage.
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}
