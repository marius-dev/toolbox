import 'dart:io';

/// Lightweight, best-effort resolver that tries to map an app path to a displayable icon file.
/// Returns a path to the icon if we can find one; otherwise returns null so callers can fall back.
class AppIconResolver {
  AppIconResolver._internal();

  static final AppIconResolver instance = AppIconResolver._internal();

  Future<String?> resolve(String appPath) async {
    try {
      if (Platform.isWindows) {
        return _getWindowsAppIcon(appPath);
      } else if (Platform.isLinux) {
        return _getLinuxAppIcon(appPath);
      } else if (Platform.isMacOS) {
        return _getMacAppIcon(appPath);
      }
    } catch (_) {
      // Ignore resolution failures and let callers fall back to a default icon.
    }

    return null;
  }

  String? _getWindowsAppIcon(String path) {
    // Without a native extractor we fall back to nearby icon files (common for some installers).
    final file = File(path);
    if (!file.existsSync()) return null;

    final parent = file.parent.path;
    final stem = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last.split('.').first
        : 'app';

    final candidates = <String>[
      if (path.toLowerCase().endsWith('.ico')) path,
      '$parent${Platform.pathSeparator}$stem.ico',
      '$parent${Platform.pathSeparator}icon.ico',
      '$parent${Platform.pathSeparator}icon.png',
    ];

    for (final candidate in candidates) {
      if (candidate.isNotEmpty && File(candidate).existsSync()) {
        return candidate;
      }
    }

    return null;
  }

  String? _getLinuxAppIcon(String appPath) {
    // If appPath is a desktop file
    if (appPath.endsWith('.desktop') && File(appPath).existsSync()) {
      final lines = File(appPath).readAsLinesSync();
      for (final line in lines) {
        if (line.startsWith('Icon=')) {
          final icon = line.substring(5).trim();
          if (icon.startsWith('/')) {
            return File(icon).existsSync() ? icon : null;
          } else {
            // Try standard icon directories
            final candidates = [
              '/usr/share/icons/hicolor/256x256/apps/$icon.png',
              '/usr/share/icons/hicolor/128x128/apps/$icon.png',
              '/usr/share/icons/hicolor/64x64/apps/$icon.png',
              '/usr/share/icons/hicolor/48x48/apps/$icon.png',
              '/usr/share/pixmaps/$icon.png',
              '/usr/share/icons/$icon.png',
            ];
            for (final candidate in candidates) {
              if (File(candidate).existsSync()) return candidate;
            }
          }
        }
      }
    }

    return null;
  }

  String? _getMacAppIcon(String appPath) {
    if (!appPath.endsWith('.app')) return null;

    final resourcesDir = Directory('$appPath/Contents/Resources');
    if (!resourcesDir.existsSync()) return null;

    final icnsFile = resourcesDir.listSync().firstWhere(
          (entity) =>
              entity is File && entity.path.toLowerCase().endsWith('.icns'),
          orElse: () => File(''),
        );

    return icnsFile is File && icnsFile.path.isNotEmpty
        ? icnsFile.path
        : null;
  }
}
