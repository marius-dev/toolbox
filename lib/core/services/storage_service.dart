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
    return {
      'isDark': prefs['isDark'] ?? true,
      'accentColor': prefs['accentColor'] ?? 0xFF6366F1,
    };
  }

  Future<void> saveThemePreferences({
    required bool isDark,
    required int accentColor,
  }) async {
    final prefs = await _readPreferences();
    prefs['isDark'] = isDark;
    prefs['accentColor'] = accentColor;
    await _writePreferences(prefs);
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
}
