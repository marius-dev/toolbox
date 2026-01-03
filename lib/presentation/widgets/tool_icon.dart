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
  static const Set<ToolId> _vsCodeLikeIds = {
    ToolId.vscode,
    ToolId.antigravity,
    ToolId.cursor,
  };

  final Tool tool;
  final double size;
  final double borderRadius;

  const ToolIcon({
    super.key,
    required this.tool,
    this.size = 42,
    double? borderRadius,
  }) : borderRadius = borderRadius ?? 10;

  @override
  Widget build(BuildContext context) {
    final iconPath = tool.iconPath;
    final hasExternalIcon =
        iconPath != null &&
        iconPath.isNotEmpty &&
        tool.isInstalled &&
        File(iconPath).existsSync();

    if (!tool.isInstalled) {
      return _buildUnavailableIcon(tool);
    }

    if (hasExternalIcon) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(iconPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(tool),
        ),
      );
    }

    return _buildFallbackIcon(tool);
  }

  Widget _buildFallbackIcon(Tool tool) {
    return _buildGradientIcon(tool);
  }

  Widget _buildUnavailableIcon(Tool tool) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _buildGradientIcon(tool),
          Positioned(
            bottom: size * 0.05,
            right: size * 0.05,
            child: Container(
              width: size * 0.36,
              height: size * 0.36,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.72),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70, width: 1),
              ),
              child: Icon(
                Icons.download_for_offline_rounded,
                color: Colors.white,
                size: size * 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientIcon(Tool tool) {
    final colors = _iconGradient(tool);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(_iconData(tool), color: Colors.white, size: size * 0.52),
    );
  }

  IconData _iconData(Tool tool) {
    if (_jetBrainsIds.contains(tool.id)) {
      return Icons.developer_mode_rounded;
    }
    if (_vsCodeLikeIds.contains(tool.id)) {
      return Icons.code_rounded;
    }
    return Icons.extension_rounded;
  }

  List<Color> _iconGradient(Tool tool) {
    if (_jetBrainsIds.contains(tool.id)) {
      return [const Color(0xFF5C2D91), const Color(0xFF9A4DFF)];
    }
    if (_vsCodeLikeIds.contains(tool.id)) {
      return [const Color(0xFF007ACC), const Color(0xFF00B4FF)];
    }

    return [const Color(0xFF1FA2FF), const Color(0xFF12D8FA)];
  }
}
