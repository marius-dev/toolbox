import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;

  StorageService._internal();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _projectsFile async {
    final path = await _localPath;
    return File('$path/projects.json');
  }

  Future<File> get _preferencesFile async {
    final path = await _localPath;
    return File('$path/preferences.json');
  }

  Future<Map<String, dynamic>> _readPreferences() async {
    try {
      final file = await _preferencesFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final decoded = json.decode(contents);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Error reading preferences: $e');
    }
    return {};
  }

  Future<void> _writePreferences(Map<String, dynamic> data) async {
    try {
      final file = await _preferencesFile;
      await file.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  // Project operations
  Future<List<Map<String, dynamic>>> loadProjects() async {
    try {
      final file = await _projectsFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return List<Map<String, dynamic>>.from(json.decode(contents));
      }
      return [];
    } catch (e) {
      debugPrint('Error loading projects: $e');
      return [];
    }
  }

  Future<void> saveProjects(List<Map<String, dynamic>> projects) async {
    try {
      final file = await _projectsFile;
      await file.writeAsString(json.encode(projects));
    } catch (e) {
      debugPrint('Error saving projects: $e');
    }
  }

  // Theme preferences
  Future<Map<String, dynamic>> getThemePreferences() async {
    final prefs = await _readPreferences();
    String? themeMode = prefs['themeMode'];

    // Legacy support for the old isDark flag
    if (themeMode == null && prefs.containsKey('isDark')) {
      themeMode = prefs['isDark'] == true ? 'dark' : 'light';
    }

    double scale = 1.0;
    final storedScale = prefs['scale'];
    if (storedScale is num) {
      scale = storedScale.toDouble();
    }

    return {
      'themeMode': themeMode ?? 'system',
      'accentColor': prefs['accentColor'] ?? 0xFF6366F1,
      'scale': scale,
    };
  }

  Future<void> saveThemePreferences({
    required ThemeMode themeMode,
    required int accentColor,
    required double appScale,
  }) async {
    final prefs = await _readPreferences();
    prefs['themeMode'] = _themeModeToString(themeMode);
    prefs.remove('isDark');
    prefs['accentColor'] = accentColor;
    prefs['scale'] = appScale;
    await _writePreferences(prefs);
  }

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

  // Hotkey preferences
  Future<Map<String, dynamic>?> getHotkeyPreference() async {
    final prefs = await _readPreferences();
    final hotkey = prefs['hotkey'];
    if (hotkey is Map<String, dynamic>) {
      return hotkey;
    }
    return null;
  }

  Future<void> saveHotkeyPreference(Map<String, dynamic>? hotkeyJson) async {
    final prefs = await _readPreferences();
    if (hotkeyJson == null) {
      prefs.remove('hotkey');
    } else {
      prefs['hotkey'] = hotkeyJson;
    }
    await _writePreferences(prefs);
  }

  // Default tool preference
  Future<String?> getDefaultToolId() async {
    final prefs = await _readPreferences();
    final id = prefs['defaultToolId'];
    if (id is String && id.isNotEmpty) {
      return id;
    }
    return null;
  }

  Future<void> saveDefaultToolId(String? toolId) async {
    final prefs = await _readPreferences();
    if (toolId == null) {
      prefs.remove('defaultToolId');
    } else {
      prefs['defaultToolId'] = toolId;
    }
    await _writePreferences(prefs);
  }
}
