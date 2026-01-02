import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/compact_layout.dart';
import '../../../domain/models/tool.dart';
import '../tool_icon.dart';
import 'tool_actions_menu.dart';
import 'tool_details.dart';
import 'tool_status_group.dart';
import 'tool_style_utils.dart';

class ToolListItem extends StatefulWidget {
  final Tool tool;
  final bool isDefault;
  final ValueChanged<ToolId>? onDefaultChanged;
  final void Function(Tool tool)? onLaunch;

  const ToolListItem({
    super.key,
    required this.tool,
    required this.isDefault,
    this.onDefaultChanged,
    this.onLaunch,
  });

  @override
  State<ToolListItem> createState() => _ToolListItemState();
}

class _ToolListItemState extends State<ToolListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = softAccentColor(context.accentColor, isDark);
    final textColor = theme.textTheme.bodyLarge!.color!;
    final mutedText = theme.textTheme.bodyMedium!.color!;
    final background = widget.isDefault
        ? accent.withOpacity(isDark ? 0.22 : 0.12)
        : _isHovering
        ? theme.dividerColor.withOpacity(isDark ? 0.12 : 0.08)
        : Colors.transparent;
    final borderColor = widget.isDefault
        ? accent.withOpacity(0.82)
        : _isHovering
        ? theme.dividerColor.withOpacity(isDark ? 0.4 : 0.32)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: context.compactValue(12),
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: widget.isDefault ? 1.2 : 1,
          ),
        ),
        child: SizedBox(
          height: context.compactValue(60),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ToolIcon(tool: tool, size: context.compactValue(34)),
              SizedBox(width: context.compactValue(12)),
              Expanded(
                child: ToolDetails(
                  tool: tool,
                  textColor: textColor,
                  mutedText: mutedText,
                ),
              ),
              SizedBox(width: context.compactValue(8)),
              if (!tool.isInstalled || widget.isDefault) ...[
                ToolStatusGroup(
                  isInstalled: tool.isInstalled,
                  isDefault: widget.isDefault,
                  accentColor: accent,
                ),
                SizedBox(width: context.compactValue(8)),
              ],
              ToolActionsMenu(
                tool: tool,
                isDefault: widget.isDefault,
                onLaunch: widget.onLaunch,
                onDefaultChanged: widget.onDefaultChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
