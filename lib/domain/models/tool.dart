import 'package:flutter/foundation.dart';

enum ToolId {
  vscode,
  antigravity,
  cursor,
  intellij,
  webstorm,
  phpstorm,
  pycharm,
  clion,
  goland,
  datagrip,
  rider,
  rubymine,
  appcode,
  fleet,
}

@immutable
class Tool {
  final ToolId id;
  final String name;
  final String? path;
  final String? iconPath;
  final bool isInstalled;

  const Tool({
    required this.id,
    required this.name,
    this.path,
    this.iconPath,
    required this.isInstalled,
  });

  Tool copyWith({String? path, String? iconPath, bool? isInstalled}) {
    return Tool(
      id: id,
      name: name,
      path: path ?? this.path,
      iconPath: iconPath ?? this.iconPath,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }
}
