import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../../domain/models/tool.dart';
import 'launcher/project_list_scroll_behavior.dart';
import 'tools/tool_list_item.dart';

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
      padding: context.compactPaddingOnly(
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
      padding: EdgeInsets.all(context.compactValue(16)),
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
          padding: context.compactPadding(horizontal: 12, vertical: 12),
          itemBuilder: (context, index) {
            final tool = widget.installed[index];
            return ToolListItem(
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
              SizedBox(height: context.compactValue(6)),
          itemCount: widget.installed.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.color;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.compactValue(20)),
        child: Text(
          'No tools found yet. Try scanning again or installing a tool.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted),
        ),
      ),
    );
  }
}
