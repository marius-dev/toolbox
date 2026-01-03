import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../domain/models/tool.dart';
import '../app_menu.dart';

enum ToolMenuAction { open, setDefault }

class ToolActionsMenu extends StatelessWidget {
  final Tool tool;
  final bool isDefault;
  final ValueChanged<ToolId>? onDefaultChanged;
  final void Function(Tool tool)? onLaunch;

  const ToolActionsMenu({
    super.key,
    required this.tool,
    required this.isDefault,
    this.onDefaultChanged,
    this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final hasOpenAction = tool.isInstalled && onLaunch != null;
    final hasDefaultAction =
        tool.isInstalled && onDefaultChanged != null && !isDefault;

    if (!hasOpenAction && !hasDefaultAction) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final menuStyle = AppMenuStyle.of(context);
    final textStyle = menuStyle.textStyle;
    final textColor = textStyle.color!;

    return AppMenuButton<ToolMenuAction>(
      tooltip: 'Tool actions',
      icon: Icon(
        Icons.more_horiz,
        color: theme.iconTheme.color,
        size: context.compactValue(18),
      ),
      position: PopupMenuPosition.under,
      onSelected: (action) {
        switch (action) {
          case ToolMenuAction.open:
            if (onLaunch != null) onLaunch!(tool);
            break;
          case ToolMenuAction.setDefault:
            onDefaultChanged?.call(tool.id);
            break;
        }
      },
      itemBuilder: (context) => [
        if (hasOpenAction)
          PopupMenuItem<ToolMenuAction>(
            value: ToolMenuAction.open,
            child: Row(
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: context.compactValue(16),
                  color: textColor,
                ),
                SizedBox(width: context.compactValue(8)),
                Text('Open', style: textStyle),
              ],
            ),
          ),
        if (hasDefaultAction)
          PopupMenuItem<ToolMenuAction>(
            value: ToolMenuAction.setDefault,
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: context.compactValue(16),
                  color: textColor,
                ),
                SizedBox(width: context.compactValue(8)),
                Text('Set as default', style: textStyle),
              ],
            ),
          ),
      ],
    );
  }
}
