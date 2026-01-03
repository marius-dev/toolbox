import 'dart:io';

/// Provides platform-specific strings for UI elements.
///
/// This class centralizes all platform-specific text to ensure consistency
/// across the application and make it easy to update platform-specific
/// terminology in one place.
///
/// All methods are static since platform detection doesn't change at runtime.
class PlatformStrings {
  PlatformStrings._();

  // ============================================================================
  // File Manager Strings
  // ============================================================================

  /// Returns the platform-specific label for revealing a file/folder.
  ///
  /// Examples:
  /// - macOS: "Reveal in Finder"
  /// - Windows: "Show in Explorer"
  /// - Linux: "Show in Files"
  static String get revealInFileManager {
    if (Platform.isMacOS) return 'Reveal in Finder';
    if (Platform.isWindows) return 'Show in Explorer';
    if (Platform.isLinux) return 'Show in Files';
    return 'Show in Files';
  }

  /// Returns the platform-specific accessibility label for revealing a file/folder.
  ///
  /// Examples:
  /// - macOS: "Reveal project in Finder"
  /// - Windows: "Show project in Explorer"
  /// - Linux: "Show project in Files"
  static String revealProjectInFileManager({String? itemName}) {
    final item = itemName ?? 'project';
    if (Platform.isMacOS) return 'Reveal $item in Finder';
    if (Platform.isWindows) return 'Show $item in Explorer';
    if (Platform.isLinux) return 'Show $item in Files';
    return 'Show $item in Files';
  }

  /// Returns the platform-specific file manager name.
  ///
  /// Examples:
  /// - macOS: "Finder"
  /// - Windows: "Explorer"
  /// - Linux: "Files"
  static String get fileManagerName {
    if (Platform.isMacOS) return 'Finder';
    if (Platform.isWindows) return 'Explorer';
    if (Platform.isLinux) return 'Files';
    return 'Files';
  }

  // ============================================================================
  // Terminal/Command Line Strings
  // ============================================================================

  /// Returns the platform-specific label for opening a terminal.
  ///
  /// Examples:
  /// - macOS/Linux: "Open in Terminal"
  /// - Windows: "Open in Command Prompt"
  static String get openInTerminal {
    if (Platform.isWindows) return 'Open in Command Prompt';
    return 'Open in Terminal';
  }

  /// Returns the platform-specific accessibility label for opening a terminal.
  static String openProjectInTerminal({String? itemName}) {
    final item = itemName ?? 'project';
    if (Platform.isWindows) return 'Open $item in Command Prompt';
    return 'Open $item in Terminal';
  }

  /// Returns the platform-specific terminal application name.
  ///
  /// Examples:
  /// - macOS/Linux: "Terminal"
  /// - Windows: "Command Prompt"
  static String get terminalName {
    if (Platform.isWindows) return 'Command Prompt';
    return 'Terminal';
  }

  // ============================================================================
  // Keyboard Modifier Strings
  // ============================================================================

  /// Returns the platform-specific primary modifier key name.
  ///
  /// Examples:
  /// - macOS: "⌘" or "Command"
  /// - Windows/Linux: "Ctrl"
  static String get primaryModifier {
    if (Platform.isMacOS) return '⌘';
    return 'Ctrl';
  }

  /// Returns the platform-specific primary modifier key name (spelled out).
  ///
  /// Examples:
  /// - macOS: "Command"
  /// - Windows/Linux: "Control"
  static String get primaryModifierName {
    if (Platform.isMacOS) return 'Command';
    return 'Control';
  }

  /// Returns the platform-specific secondary modifier key name.
  ///
  /// Examples:
  /// - macOS: "⌥" or "Option"
  /// - Windows/Linux: "Alt"
  static String get secondaryModifier {
    if (Platform.isMacOS) return '⌥';
    return 'Alt';
  }

  /// Returns the platform-specific secondary modifier key name (spelled out).
  ///
  /// Examples:
  /// - macOS: "Option"
  /// - Windows/Linux: "Alt"
  static String get secondaryModifierName {
    if (Platform.isMacOS) return 'Option';
    return 'Alt';
  }

  /// Returns the shift key symbol or name.
  static String get shiftModifier => '⇧';

  /// Returns the shift key name (spelled out).
  static String get shiftModifierName => 'Shift';

  // ============================================================================
  // Application Menu Strings
  // ============================================================================

  /// Returns the platform-specific preferences menu label.
  ///
  /// Examples:
  /// - macOS: "Preferences..."
  /// - Windows/Linux: "Settings..."
  static String get preferencesLabel {
    if (Platform.isMacOS) return 'Preferences...';
    return 'Settings...';
  }

  /// Returns the platform-specific quit/exit label.
  ///
  /// Examples:
  /// - macOS: "Quit"
  /// - Windows/Linux: "Exit"
  static String quitApplication({required String appName}) {
    if (Platform.isMacOS) return 'Quit $appName';
    return 'Exit $appName';
  }

  // ============================================================================
  // Path Separators
  // ============================================================================

  /// Returns the platform-specific path separator.
  ///
  /// Examples:
  /// - macOS/Linux: "/"
  /// - Windows: "\\"
  static String get pathSeparator => Platform.pathSeparator;

  /// Returns the platform-specific path display format.
  ///
  /// Useful for displaying paths in a platform-appropriate way.
  static String formatPath(String path) {
    // On Windows, convert forward slashes to backslashes for display
    if (Platform.isWindows) {
      return path.replaceAll('/', '\\');
    }
    return path;
  }

  // ============================================================================
  // Utility Methods
  // ============================================================================

  /// Returns true if running on macOS.
  static bool get isMacOS => Platform.isMacOS;

  /// Returns true if running on Windows.
  static bool get isWindows => Platform.isWindows;

  /// Returns true if running on Linux.
  static bool get isLinux => Platform.isLinux;

  /// Returns the current platform name.
  ///
  /// Examples: "macOS", "Windows", "Linux", "Unknown"
  static String get platformName {
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }
}
