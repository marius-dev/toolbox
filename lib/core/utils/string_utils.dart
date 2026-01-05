import 'dart:io';

import 'package:path/path.dart' as path;

class StringUtils {
  static final String? _homeDirectory =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

  static final String? _normalizedHomeDirectory = _homeDirectory == null
      ? null
      : path.normalize(path.absolute(_homeDirectory!));

  static String ellipsisStart(String value, {int maxLength = 40}) {
    if (value.length <= maxLength) return value;
    final keep = maxLength - 3;
    return '...${value.substring(value.length - keep)}';
  }

  static String replaceHomeWithTilde(String value) {
    final home = _normalizedHomeDirectory;
    if (home == null || value.isEmpty) return value;

    final normalizedValue = path.normalize(path.absolute(value));
    if (normalizedValue == home) {
      return '~';
    }

    if (!path.isWithin(home, normalizedValue)) {
      return value;
    }

    final relative = path.relative(normalizedValue, from: home);
    if (relative.isEmpty) {
      return '~';
    }

    return path.join('~', relative);
  }
}
