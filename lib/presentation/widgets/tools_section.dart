import 'package:flutter/material.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/utils/string_utils.dart';
import '../../domain/models/tool.dart';

class ToolsSection extends StatefulWidget {
  final List<Tool> installed;
  final List<Tool> available;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(Tool tool)? onLaunch;

  const ToolsSection({
    Key? key,
    required this.installed,
    required this.available,
    required this.isLoading,
    required this.onRefresh,
    this.onLaunch,
  }) : super(key: key);

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

  @override
  State<ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<ToolsSection> {
  bool _installedExpanded = true;
  bool _availableExpanded = true;

  @override
  Widget build(BuildContext context) {
    final panelColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.9);
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(context),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.all(5),
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(5),
                      children: [
                        _buildSection(
                          context,
                          title: 'Installed',
                          subtitle: 'Tools already available on this device',
                          tools: widget.installed,
                          emptyLabel:
                              'Nothing detected yet. Try rescanning or installing a tool.',
                          expanded: _installedExpanded,
                          onToggle: () => setState(
                            () => _installedExpanded = !_installedExpanded,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSection(
                          context,
                          title: 'Available tools',
                          subtitle:
                              'Autodiscovered locations for common editors and viewers',
                          tools: widget.available,
                          emptyLabel:
                              'Everything we know is already installed. Add more tools to see them here.',
                          expanded: _availableExpanded,
                          onToggle: () => setState(
                            () => _availableExpanded = !_availableExpanded,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final accentColor = ThemeProvider.instance.accentColor;
    final mutedText = Theme.of(context).textTheme.bodyMedium!.color!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tool autodiscovery',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'We look for VS Code, the JetBrains IDEs (IntelliJ, WebStorm, PhpStorm, etc.) and Preview and surface the install paths.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: mutedText.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: widget.onRefresh,
          style: TextButton.styleFrom(
            foregroundColor: accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Rescan'),
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: mutedText,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tools.length.toString(),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: mutedText.withOpacity(0.8)),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          if (tools.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(emptyLabel, style: TextStyle(color: mutedText)),
            )
          else
            ...tools.map((tool) => _buildToolTile(tool, textColor)),
        ],
      ],
    );
  }

  Widget _buildToolTile(Tool tool, Color textColor) {
    return _ToolTile(
      tool: tool,
      textColor: textColor,
      onLaunch: widget.onLaunch,
    );
  }
}

class _ToolTile extends StatefulWidget {
  final Tool tool;
  final Color textColor;
  final void Function(Tool tool)? onLaunch;

  const _ToolTile({required this.tool, required this.textColor, this.onLaunch});

  @override
  State<_ToolTile> createState() => _ToolTileState();
}

class _ToolTileState extends State<_ToolTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withOpacity(0.01)
        : Colors.black.withOpacity(0.01);
    final hoverColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);
    final shadowColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final accentColor = ThemeProvider.instance.accentColor;
    final pathText = tool.path != null
        ? StringUtils.ellipsisStart(tool.path!, maxLength: 60)
        : 'Path not found';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _isHovering ? hoverColor : baseColor,
          borderRadius: BorderRadius.zero,
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            _buildIcon(tool),
            const SizedBox(width: 12),
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
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _buildStatusBadge(tool, accentColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 14,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pathText,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (tool.isInstalled && widget.onLaunch != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => widget.onLaunch!(tool),
                  child: const Text('Open'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Tool tool) {
    final colors = _iconGradient(tool);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_iconData(tool), color: Colors.white, size: 22),
    );
  }

  IconData _iconData(Tool tool) {
    if (ToolsSection._jetBrainsIds.contains(tool.id)) {
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
    if (ToolsSection._jetBrainsIds.contains(tool.id)) {
      return [const Color(0xFF5C2D91), const Color(0xFF9A4DFF)];
    }

    if (tool.id == ToolId.vscode) {
      return [const Color(0xFF007ACC), const Color(0xFF00B4FF)];
    }

    return [const Color(0xFF1FA2FF), const Color(0xFF12D8FA)];
  }

  Widget _buildStatusBadge(Tool tool, Color accentColor) {
    final isInstalled = tool.isInstalled;
    final color = isInstalled ? accentColor : Colors.orange;
    final background = isInstalled
        ? accentColor.withOpacity(0.14)
        : Colors.orange.withOpacity(0.14);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isInstalled ? Icons.check_circle : Icons.search_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isInstalled ? 'Installed' : 'Not found',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
