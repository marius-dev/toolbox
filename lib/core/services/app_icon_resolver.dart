import 'dart:io';

/// Lightweight, best-effort resolver that tries to map an app path to a displayable icon file.
/// Returns a path to the icon if we can find one; otherwise returns null so callers can fall back.
///
/// On macOS, this resolver now includes a more robust, case-insensitive check when searching for
/// icon files within the Resources directory to better handle non-standard applications like VS Code.
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
    } catch (e) {
      // Log error for debugging if needed, but gracefully ignore resolution failures
      // print('AppIconResolver failed for $appPath: $e');
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

  /// macOS: return the actual app icon as declared in Info.plist.
  String? _getMacAppIcon(String appPath) {
    final bundleRoot = _findAppBundleRoot(appPath);
    if (bundleRoot == null) return null;

    final infoPlist = File('$bundleRoot/Contents/Info.plist');
    final resourcesDir = Directory('$bundleRoot/Contents/Resources');
    if (!infoPlist.existsSync() || !resourcesDir.existsSync()) return null;

    final xml = _readPlistXml(infoPlist.path);
    if (xml == null || xml.isEmpty) return _fallbackFirstIcns(resourcesDir);

    // 1) CFBundleIconFile (simple case)
    final bundleIconFile = _extractPlistString(xml, 'CFBundleIconFile');
    if (bundleIconFile != null) {
      final resolved = _resolveIcnsInResources(resourcesDir, bundleIconFile);
      if (resolved != null) return resolved;
    }

    // 2) CFBundleIcons/CFBundlePrimaryIcon/CFBundleIconFiles (array) – prefer the last (largest).
    final primaryIconFiles = _extractPrimaryIconFiles(xml);
    if (primaryIconFiles.isNotEmpty) {
      // Try from last to first, since the largest size is usually last.
      for (var i = primaryIconFiles.length - 1; i >= 0; i--) {
        final resolved = _resolveIcnsInResources(
          resourcesDir,
          primaryIconFiles[i],
        );
        if (resolved != null) return resolved;
      }
    }

    // 3) CFBundleIconName (rare but seen)
    final bundleIconName = _extractPlistString(xml, 'CFBundleIconName');
    if (bundleIconName != null) {
      final resolved = _resolveIcnsInResources(resourcesDir, bundleIconName);
      if (resolved != null) return resolved;
    }

    // 4) Pragmatic fallbacks: try common names (e.g., VS Code)
    const commonBasenames = [
      'AppIcon',
      'AppIcon-mac',
      'Code', // Common for VS Code
      'VSCode',
      'Visual Studio Code',
      'ElectronApp',
    ];
    for (final base in commonBasenames) {
      final resolved = _resolveIcnsInResources(resourcesDir, base);
      if (resolved != null) return resolved;
    }

    // 5) Last resort: first .icns in Resources
    return _fallbackFirstIcns(resourcesDir);
  }

  /// Given a path that may be the .app or a file *inside* the .app, return the .app root.
  String? _findAppBundleRoot(String path) {
    var current = FileSystemEntity.isDirectorySync(path)
        ? Directory(path)
        : File(path).parent;
    // Walk up until we see a folder ending with ".app" or we reach filesystem root.
    while (true) {
      if (current.path.toLowerCase().endsWith('.app') &&
          Directory(current.path).existsSync()) {
        return current.path;
      }
      final parent = current.parent;
      if (parent.path == current.path) break; // reached root
      current = parent;
    }
    return null;
  }

  /// Read Info.plist as XML. If binary, use `plutil` to convert.
  String? _readPlistXml(String plistPath) {
    try {
      final raw = File(plistPath).readAsStringSync();
      if (raw.trimLeft().startsWith('<?xml')) {
        return raw;
      }
    } catch (_) {
      // fall through to plutil conversion below
    }
    try {
      // Use plutil to convert a binary plist to XML if necessary.
      final result = Process.runSync('plutil', [
        '-convert',
        'xml1',
        '-o',
        '-',
        plistPath,
      ], runInShell: true);
      if (result.exitCode == 0 &&
          result.stdout is String &&
          (result.stdout as String).isNotEmpty) {
        return result.stdout as String;
      }
    } catch (_) {
      // If plutil is unavailable or fails, we cannot parse binary plist.
    }
    return null;
  }

  /// Extract the first <string> value immediately following the given <key>.
  String? _extractPlistString(String xml, String keyName) {
    final keyRegex = RegExp(
      '<key>\\s*$keyName\\s*</key>\\s*(<string>([^<]+)</string>)',
      multiLine: true,
    );
    final m = keyRegex.firstMatch(xml);
    if (m != null && m.groupCount >= 2) {
      return m.group(2)?.trim();
    }
    return null;
  }

  /// Extract CFBundleIcons/CFBundlePrimaryIcon/CFBundleIconFiles array entries.
  List<String> _extractPrimaryIconFiles(String xml) {
    // Capture the CFBundleIcons dict
    final iconsSection = _extractSection(xml, 'CFBundleIcons');
    if (iconsSection == null) return const [];

    // Then capture CFBundlePrimaryIcon dict within it
    final primarySection = _extractSection(iconsSection, 'CFBundlePrimaryIcon');
    if (primarySection == null) return const [];

    // Finally capture CFBundleIconFiles array strings
    final arraySection = _extractSection(
      primarySection,
      'CFBundleIconFiles',
      expectArray: true,
    );
    if (arraySection == null) return const [];

    final strings = RegExp('<string>([^<]+)</string>').allMatches(arraySection);
    return strings.map((m) => m.group(1)!.trim()).toList();
  }

  /// Extract the XML snippet that follows a given <key> name.
  /// If expectArray is true, return only the <array>…</array> block that follows.
  String? _extractSection(
    String xml,
    String keyName, {
    bool expectArray = false,
  }) {
    final key = RegExp(
      '<key>\\s*$keyName\\s*</key>',
      multiLine: true,
    ).firstMatch(xml);
    if (key == null) return null;

    final startIndex = key.end;
    if (expectArray) {
      final arrayOpen = xml.indexOf('<array>', startIndex);
      if (arrayOpen == -1) return null;
      // Find closing tag, accounting for potential nested XML structure (though unlikely here)
      final arrayClose = xml.indexOf('</array>', arrayOpen);
      if (arrayClose == -1) return null;
      return xml.substring(arrayOpen, arrayClose + '</array>'.length);
    }

    // Return the tail after the key, caller can further parse it.
    return xml.substring(startIndex);
  }

  /// Try to resolve a basename (with/without .icns) inside Resources.
  /// IMPROVEMENT: Added case-insensitive matching for icon names.
  String? _resolveIcnsInResources(
    Directory resourcesDir,
    String basenameOrPath,
  ) {
    // If the value is already a path, try absolute or Resources-relative resolution.
    final candidatePaths = <String>[];

    if (basenameOrPath.contains(Platform.pathSeparator)) {
      // Might be "AppIcon.icns" or "Resources/AppIcon.icns"
      final p = basenameOrPath.startsWith('/')
          ? basenameOrPath
          : '${resourcesDir.path}/$basenameOrPath';
      candidatePaths.add(p);
    } else {
      // Just a basename – try with and without .icns
      candidatePaths.add('${resourcesDir.path}/$basenameOrPath');
      candidatePaths.add('${resourcesDir.path}/$basenameOrPath.icns');
    }

    for (final p in candidatePaths) {
      final f = File(p);
      // Check if the file exists and is an .icns file
      if (f.existsSync() && p.toLowerCase().endsWith('.icns')) {
        return f.path;
      }
    }

    // If it didn't resolve directly, search Resources for any .icns that starts with the basename.
    final base = basenameOrPath.toLowerCase().endsWith('.icns')
        ? basenameOrPath.substring(0, basenameOrPath.length - 5)
        : basenameOrPath;

    final baseLower = base.toLowerCase(); // Case-insensitive base match

    try {
      for (final entity in resourcesDir.listSync()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.icns')) {
          final name = entity.uri.pathSegments.isNotEmpty
              ? entity.uri.pathSegments.last
              : '';

          // Case-insensitive check on the basename match
          if (name.toLowerCase().startsWith(baseLower)) {
            return entity.path;
          }
        }
      }
    } catch (_) {
      // ignore
    }

    return null;
  }

  String? _fallbackFirstIcns(Directory resourcesDir) {
    try {
      final icns =
          resourcesDir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.icns'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      return icns.isNotEmpty ? icns.first.path : null;
    } catch (_) {
      return null;
    }
  }
}
