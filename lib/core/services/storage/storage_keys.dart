/// Constants for storage keys used across different storage services.
///
/// Centralizes all storage keys to avoid duplication and typos.
class StorageKeys {
  StorageKeys._();

  // File names
  static const String projectsFile = 'projects.json';
  static const String workspacesFile = 'workspaces.json';
  static const String preferencesFile = 'preferences.json';

  // Preference keys
  static const String themeMode = 'themeMode';
  static const String accentColor = 'accentColor';
  static const String scale = 'scale';
  static const String glassStyle = 'glassStyle';
  static const String hotkey = 'hotkey';
  static const String defaultToolId = 'defaultToolId';
  static const String selectedWorkspaceId = 'selectedWorkspaceId';

  // Legacy keys
  static const String isDark = 'isDark';
}
