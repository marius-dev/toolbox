import 'package:flutter/material.dart';

import '../../core/utils/compact_layout.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/utils/string_utils.dart';
import '../../domain/models/tool.dart';
import 'listing_item_container.dart';
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
  bool _installedExpanded = true;
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
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = colorScheme.surface;
    final borderColor =
        colorScheme.onSurface.withOpacity(isDark ? 0.08 : 0.06);

    return Padding(
      padding: CompactLayout.only(
        context,
        left: 10,
        top: 6,
        right: 10,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: widget.isLoading
                ? Container(
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(
                        CompactLayout.value(context, 12),
                      ),
                      border: Border.all(color: borderColor),
                    ),
                    padding: EdgeInsets.all(CompactLayout.value(context, 8)),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : ListView(
                    padding: EdgeInsets.only(
                      top: CompactLayout.value(context, 2),
                      bottom: CompactLayout.value(context, 3),
                    ),
                    children: [
                      _buildSectionCard(
                        context,
                        panelColor: panelColor,
                        borderColor: borderColor,
                        title: 'Installed',
                        subtitle: 'Installed on this device',
                        tools: widget.installed,
                        emptyLabel:
                            'No tools found yet. Try scanning again or installing a tool.',
                        expanded: _installedExpanded,
                        onToggle: () => setState(
                          () => _installedExpanded = !_installedExpanded,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required Color panelColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required List<Tool> tools,
    required String emptyLabel,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 10)),
        border: Border.all(color: borderColor),
      ),
      padding: EdgeInsets.all(CompactLayout.value(context, 8)),
      child: _buildSection(
        context,
        title: title,
        subtitle: subtitle,
        tools: tools,
        emptyLabel: emptyLabel,
        expanded: expanded,
        onToggle: onToggle,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Tool> tools,
    required String emptyLabel,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final mutedText = Theme.of(context).textTheme.bodyMedium!.color!;
    final accentColor = ThemeProvider.instance.accentColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.black.withOpacity(0.04);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius:
              BorderRadius.circular(CompactLayout.value(context, 6)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: CompactLayout.value(context, 4),
            ),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: CompactLayout.value(context, 16),
                  color: mutedText,
                ),
                SizedBox(width: CompactLayout.value(context, 4)),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: CompactLayout.value(context, 13),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Container(
                  margin: EdgeInsets.only(left: CompactLayout.value(context, 8)),
                  padding: EdgeInsets.symmetric(
                    horizontal: CompactLayout.value(context, 7),
                    vertical: CompactLayout.value(context, 2),
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(CompactLayout.value(context, 6)),
                  ),
                  child: Text(
                    tools.length.toString(),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: CompactLayout.value(context, 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: CompactLayout.value(context, 2)),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: mutedText.withOpacity(0.8)),
        ),
        if (expanded) ...[
          SizedBox(height: CompactLayout.value(context, 6)),
          if (tools.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: CompactLayout.value(context, 10),
                vertical: CompactLayout.value(context, 10),
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(
                  CompactLayout.value(context, 6),
                ),
              ),
              child: Text(emptyLabel, style: TextStyle(color: mutedText)),
            )
          else
            ...tools.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final tool = entry.value;
                return Column(
                  children: [
                    if (index > 0)
                      Divider(
                        height: 1,
                        thickness: 0.7,
                        color: dividerColor,
                      ),
                    _buildToolTile(tool, textColor),
                  ],
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildToolTile(Tool tool, Color textColor) {
    return _ToolTile(
      tool: tool,
      textColor: textColor,
      onLaunch: widget.onLaunch,
      isDefault: _currentDefaultId == tool.id,
      onDefaultChanged: (id) {
        setState(() {
          _currentDefaultId = id;
        });
        widget.onDefaultChanged?.call(id);
      },
    );
  }
}

class _ToolTile extends StatefulWidget {
  final Tool tool;
  final Color textColor;
  final bool isDefault;
  final ValueChanged<ToolId>? onDefaultChanged;
  final void Function(Tool tool)? onLaunch;

  const _ToolTile({
    required this.tool,
    required this.textColor,
    required this.isDefault,
    this.onDefaultChanged,
    this.onLaunch,
  });

  @override
  State<_ToolTile> createState() => _ToolTileState();
}

enum _ToolTileAction {
  open,
  setDefault,
}

class _ToolTileState extends State<_ToolTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final theme = Theme.of(context);
    final accentColor = ThemeProvider.instance.accentColor;
    final mutedText = theme.textTheme.bodyMedium!.color!;
    final displayPath = tool.path != null
        ? StringUtils.replaceHomeWithTilde(tool.path!)
        : null;
    final pathText = displayPath != null
        ? StringUtils.ellipsisStart(displayPath, maxLength: 60)
        : 'Path not found';
    final canToggleDefault =
        tool.isInstalled && widget.onDefaultChanged != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: ListingItemContainer(
        margin: EdgeInsets.symmetric(
          vertical: CompactLayout.value(context, 3),
        ),
        isActive: false,
        isHovering: _isHovering,
        isDisabled: !tool.isInstalled,
        child: Row(
          children: [
            ToolIcon(
              tool: tool,
              size: CompactLayout.value(context, 24),
            ),
            SizedBox(width: CompactLayout.value(context, 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tool.name,
                          style: TextStyle(
                            color: widget.textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: CompactLayout.value(context, 12),
                          ),
                        ),
                      ),
                      if (!tool.isInstalled)
                        Container(
                          margin: EdgeInsets.only(
                            left: CompactLayout.value(context, 8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: CompactLayout.value(context, 6),
                            vertical: CompactLayout.value(context, 2),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(
                              CompactLayout.value(context, 4),
                            ),
                          ),
                          child: Text(
                            'Not installed',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: CompactLayout.value(context, 10),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (widget.isDefault)
                        Container(
                          margin: EdgeInsets.only(
                            left: CompactLayout.value(context, 8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: CompactLayout.value(context, 6),
                            vertical: CompactLayout.value(context, 2),
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(
                              CompactLayout.value(context, 10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: CompactLayout.value(context, 14),
                                color: accentColor,
                              ),
                              SizedBox(width: CompactLayout.value(context, 4)),
                              Text(
                                'Default',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: CompactLayout.value(context, 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: CompactLayout.value(context, 4)),
                  Text(
                    tool.description,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: mutedText.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: CompactLayout.value(context, 5)),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: CompactLayout.value(context, 14),
                        color: theme.iconTheme.color,
                      ),
                      SizedBox(width: CompactLayout.value(context, 5)),
                      Expanded(
                        child: Text(
                          pathText,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: mutedText.withOpacity(0.8),
                            fontSize: CompactLayout.value(context, 11),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildActionsMenu(
              context,
              tool: tool,
              canToggleDefault: canToggleDefault,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsMenu(
    BuildContext context, {
    required Tool tool,
    required bool canToggleDefault,
  }) {
    final hasOpenAction = tool.isInstalled && widget.onLaunch != null;
    final hasDefaultAction = canToggleDefault && !widget.isDefault;

    if (!hasOpenAction && !hasDefaultAction) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.black.withOpacity(0.7)
        : colorScheme.surface;
    final borderColor = colorScheme.onSurface.withOpacity(
      isDark ? 0.08 : 0.06,
    );
    final textColor = theme.textTheme.bodyMedium!.color!;

    return Padding(
      padding: EdgeInsets.only(left: CompactLayout.value(context, 4)),
      child: PopupMenuButton<_ToolTileAction>(
        icon: Icon(
          Icons.more_horiz,
          color: theme.iconTheme.color,
          size: CompactLayout.value(context, 16),
        ),
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        onSelected: (action) {
          switch (action) {
            case _ToolTileAction.open:
              if (widget.onLaunch != null) {
                widget.onLaunch!(tool);
              }
              break;
            case _ToolTileAction.setDefault:
              widget.onDefaultChanged?.call(tool.id);
              break;
          }
        },
        itemBuilder: (context) => [
          if (hasOpenAction)
            PopupMenuItem<_ToolTileAction>(
              value: _ToolTileAction.open,
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: CompactLayout.value(context, 16),
                    color: textColor,
                  ),
                  SizedBox(width: CompactLayout.value(context, 6)),
                  Text(
                    'Open',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          if (hasDefaultAction)
            PopupMenuItem<_ToolTileAction>(
              value: _ToolTileAction.setDefault,
              child: Row(
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: CompactLayout.value(context, 16),
                    color: textColor,
                  ),
                  SizedBox(width: CompactLayout.value(context, 6)),
                  Text(
                    'Set as default',
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
