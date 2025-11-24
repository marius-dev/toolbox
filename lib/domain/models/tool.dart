import 'package:flutter/foundation.dart';

enum ToolId {
  vscode,
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
  preview,
}

@immutable
class Tool {
  final ToolId id;
  final String name;
  final String description;
  final String? path;
  final bool isInstalled;

  const Tool({
    required this.id,
    required this.name,
    required this.description,
    this.path,
    required this.isInstalled,
  });

  Tool copyWith({
    String? path,
    bool? isInstalled,
  }) {
    return Tool(
      id: id,
      name: name,
      description: description,
      path: path ?? this.path,
      isInstalled: isInstalled ?? this.isInstalled,
    );
  }
}
