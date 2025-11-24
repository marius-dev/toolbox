import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/models/tool.dart';

/// Shared icon for displaying tools with either resolved app icons or
/// branded fallbacks.
class ToolIcon extends StatelessWidget {
  static const Set<ToolId> _jetBrainsIds = {
    ToolId.intellij,
    ToolId.webstorm,
    ToolId.phpstorm,
    ToolId.pycharm,
    ToolId.clion,
    ToolId.goland,
    ToolId.datagrip,
    ToolId.rider,
    ToolId.rubymine,
    ToolId.appcode,
    ToolId.fleet,
  };

  final Tool tool;
  final double size;
  final double borderRadius;

  const ToolIcon({
    Key? key,
    required this.tool,
    this.size = 42,
    double? borderRadius,
  })  : borderRadius = borderRadius ?? 10,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconPath = tool.iconPath;
    final hasExternalIcon = iconPath != null &&
        iconPath.isNotEmpty &&
        tool.isInstalled &&
        File(iconPath).existsSync();

    if (!tool.isInstalled) {
      return _buildUnavailableIcon();
    }

    if (hasExternalIcon) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(iconPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
        ),
      );
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    final colors = _iconGradient(tool);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        _iconData(tool),
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }

  Widget _buildUnavailableIcon() {
    final colors = _uninstalledGradient();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.download_for_offline_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }

  IconData _iconData(Tool tool) {
    if (_jetBrainsIds.contains(tool.id)) {
      return Icons.developer_mode_rounded;
    }
    if (tool.id == ToolId.vscode) {
      return Icons.code_rounded;
    }
    if (tool.id == ToolId.preview) {
      return Icons.image_rounded;
    }
    return Icons.extension_rounded;
  }

  List<Color> _iconGradient(Tool tool) {
    if (_jetBrainsIds.contains(tool.id)) {
      return [const Color(0xFF5C2D91), const Color(0xFF9A4DFF)];
    }

    if (tool.id == ToolId.vscode) {
      return [const Color(0xFF007ACC), const Color(0xFF00B4FF)];
    }

    return [const Color(0xFF1FA2FF), const Color(0xFF12D8FA)];
  }

  List<Color> _uninstalledGradient() {
    return [
      Colors.blueGrey.shade700,
      Colors.blueGrey.shade500,
    ];
  }
}
