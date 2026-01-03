import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_extensions.dart';

part 'launcher_tab_chip.dart';

enum LauncherTab { tools, projects }

class LauncherTabBar extends StatelessWidget {
  final LauncherTab selectedTab;
  final ValueChanged<LauncherTab> onTabSelected;

  const LauncherTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    // Subtler border for minimal look
    final outline = Theme.of(context).dividerColor.withValues(alpha: 0.3);
    final baseText = Theme.of(context).textTheme.bodyMedium!.color!;

    return Container(
      padding: EdgeInsets.all(context.compactValue(DesignTokens.space1)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            label: 'Projects',
            icon: Icons.folder_rounded,
            isActive: selectedTab == LauncherTab.projects,
            accent: accent,
            textColor: baseText,
            onTap: () => onTabSelected(LauncherTab.projects),
          ),
          SizedBox(width: context.compactValue(DesignTokens.space1)),
          _ModeChip(
            label: 'Tools',
            icon: Icons.grid_view_rounded,
            isActive: selectedTab == LauncherTab.tools,
            accent: accent,
            textColor: baseText,
            onTap: () => onTabSelected(LauncherTab.tools),
          ),
        ],
      ),
    );
  }
}
