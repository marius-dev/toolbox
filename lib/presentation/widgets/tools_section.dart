import 'package:flutter/material.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';
import '../../core/utils/string_utils.dart';
import '../../domain/models/tool.dart';
import 'app_menu.dart';
import 'launcher/project_list_scroll_behavior.dart';
import 'tool_icon.dart';

class ToolsSection extends StatefulWidget {
  final List<Tool> installed;
  final bool isLoading;
  final ToolId? defaultToolId;
  final ValueChanged<ToolId>? onDefaultChanged;
  final void Function(Tool tool)? onLaunch;

  const ToolsSection({
    super.key,
    required this.installed,
    required this.isLoading,
    required this.defaultToolId,
    this.onDefaultChanged,
    this.onLaunch,
  });

  @override
  State<ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<ToolsSection> {
  ToolId? _currentDefaultId;

  @override
  void initState() {
    super.initState();
    _currentDefaultId = widget.defaultToolId;
  }

  @override
  void didUpdateWidget(covariant ToolsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.defaultToolId != oldWidget.defaultToolId) {
      _currentDefaultId = widget.defaultToolId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.black.withOpacity(0.5)
        : Colors.white.withOpacity(0.9);
    final borderColor = theme.dividerColor.withOpacity(0.16);

    return Padding(
      padding: CompactLayout.only(
        context,
        left: 10,
        top: 6,
        right: 10,
        bottom: 14,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: widget.isLoading
              ? _buildLoadingState(context)
              : _buildToolsList(context),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(CompactLayout.value(context, 16)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildToolsList(BuildContext context) {
    if (widget.installed.isEmpty) {
      return _buildEmptyState(context);
    }

    return ScrollConfiguration(
      behavior: const ProjectListScrollBehavior(),
      child: Scrollbar(
        radius: const Radius.circular(6),
        thickness: 4,
        child: ListView.separated(
          padding: CompactLayout.symmetric(
            context,
            horizontal: 12,
            vertical: 12,
          ),
          itemBuilder: (context, index) {
            final tool = widget.installed[index];
            return _ToolListItem(
              tool: tool,
              isDefault: _currentDefaultId == tool.id,
              onLaunch: widget.onLaunch,
              onDefaultChanged: (id) {
                setState(() => _currentDefaultId = id);
                widget.onDefaultChanged?.call(id);
              },
            );
          },
          separatorBuilder: (context, _) =>
              SizedBox(height: CompactLayout.value(context, 6)),
          itemCount: widget.installed.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(CompactLayout.value(context, 20)),
        child: Text(
          'No tools found yet. Try scanning again or installing a tool.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
      ),
    );
  }
}

class _ToolListItem extends StatefulWidget {
  final Tool tool;
  final bool isDefault;
  final ValueChanged<ToolId>? onDefaultChanged;
  final void Function(Tool tool)? onLaunch;

  const _ToolListItem({
    required this.tool,
    required this.isDefault,
    this.onDefaultChanged,
    this.onLaunch,
  });

  @override
  State<_ToolListItem> createState() => _ToolListItemState();
}

class _ToolListItemState extends State<_ToolListItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _softAccentColor(ThemeProvider.instance.accentColor, isDark);
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
          horizontal: CompactLayout.value(context, 12),
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
          height: CompactLayout.value(context, 60),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ToolIcon(tool: tool, size: CompactLayout.value(context, 34)),
              SizedBox(width: CompactLayout.value(context, 12)),
              Expanded(
                child: _ToolDetails(
                  tool: tool,
                  textColor: textColor,
                  mutedText: mutedText,
                ),
              ),
              SizedBox(width: CompactLayout.value(context, 8)),
              if (!tool.isInstalled || widget.isDefault) ...[
                _ToolStatusGroup(
                  isInstalled: tool.isInstalled,
                  isDefault: widget.isDefault,
                  accentColor: accent,
                ),
                SizedBox(width: CompactLayout.value(context, 8)),
              ],
              _ToolActionsMenu(
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

class _ToolDetails extends StatelessWidget {
  final Tool tool;
  final Color textColor;
  final Color mutedText;

  const _ToolDetails({
    required this.tool,
    required this.textColor,
    required this.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    final displayPath = tool.path != null
        ? StringUtils.replaceHomeWithTilde(tool.path!)
        : null;
    final pathText = displayPath != null
        ? StringUtils.ellipsisStart(displayPath, maxLength: 60)
        : 'Path not found';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tool.name,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: CompactLayout.value(context, 13),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: CompactLayout.value(context, 6)),
        Row(
          children: [
            Icon(
              Icons.folder_rounded,
              size: CompactLayout.value(context, 15),
              color: Theme.of(context).iconTheme.color,
            ),
            SizedBox(width: CompactLayout.value(context, 6)),
            Expanded(
              child: Text(
                pathText,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: mutedText.withOpacity(0.8),
                  fontSize: CompactLayout.value(context, 11),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolStatusGroup extends StatelessWidget {
  final bool isInstalled;
  final bool isDefault;
  final Color accentColor;

  const _ToolStatusGroup({
    required this.isInstalled,
    required this.isDefault,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (!isInstalled) {
      chips.add(
        _StatusChip(
          label: 'Not installed',
          color: Colors.red,
          background: Colors.red.withOpacity(0.16),
        ),
      );
    }

    if (isDefault) {
      chips.add(
        _StatusChip(
          label: 'Default',
          color: accentColor,
          icon: Icons.check_rounded,
          background: accentColor.withOpacity(0.16),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) SizedBox(width: CompactLayout.value(context, 6)),
          chips[i],
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: CompactLayout.value(context, 8)),
      padding: EdgeInsets.symmetric(
        horizontal: CompactLayout.value(context, 7),
        vertical: CompactLayout.value(context, 3),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: CompactLayout.value(context, 13), color: color),
            SizedBox(width: CompactLayout.value(context, 4)),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: CompactLayout.value(context, 10),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ToolMenuAction { open, setDefault }

class _ToolActionsMenu extends StatelessWidget {
  final Tool tool;
  final bool isDefault;
  final ValueChanged<ToolId>? onDefaultChanged;
  final void Function(Tool tool)? onLaunch;

  const _ToolActionsMenu({
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

    return AppMenuButton<_ToolMenuAction>(
      tooltip: 'Tool actions',
      icon: Icon(
        Icons.more_horiz,
        color: theme.iconTheme.color,
        size: CompactLayout.value(context, 18),
      ),
      position: PopupMenuPosition.under,
      onSelected: (action) {
        switch (action) {
          case _ToolMenuAction.open:
            if (onLaunch != null) onLaunch!(tool);
            break;
          case _ToolMenuAction.setDefault:
            onDefaultChanged?.call(tool.id);
            break;
        }
      },
      itemBuilder: (context) => [
        if (hasOpenAction)
          PopupMenuItem<_ToolMenuAction>(
            value: _ToolMenuAction.open,
            child: Row(
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: CompactLayout.value(context, 16),
                  color: textColor,
                ),
                SizedBox(width: CompactLayout.value(context, 8)),
                Text('Open', style: textStyle),
              ],
            ),
          ),
        if (hasDefaultAction)
          PopupMenuItem<_ToolMenuAction>(
            value: _ToolMenuAction.setDefault,
            child: Row(
              children: [
                Icon(
                  Icons.check_rounded,
                  size: CompactLayout.value(context, 16),
                  color: textColor,
                ),
                SizedBox(width: CompactLayout.value(context, 8)),
                Text('Set as default', style: textStyle),
              ],
            ),
          ),
      ],
    );
  }
}

Color _softAccentColor(Color color, bool isDarkMode) {
  if (!isDarkMode) return color;
  return Color.lerp(color, Colors.white, 0.3)!;
}
