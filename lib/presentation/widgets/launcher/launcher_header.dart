import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/workspace_icons.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../domain/models/workspace.dart';
import '../app_menu.dart';
import 'launcher_tab_bar.dart';

part 'launcher_header_buttons.dart';

class LauncherHeader extends StatelessWidget {
  final LauncherTab selectedTab;
  final ValueChanged<LauncherTab> onTabSelected;
  final VoidCallback onPreferencesPressed;
  final bool hasSyncErrors;
  final bool isSyncing;
  final VoidCallback onSyncMetadata;
  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final bool isWorkspaceLoading;
  final ValueChanged<String> onWorkspaceSelected;
  final VoidCallback onManageWorkspaces;

  const LauncherHeader({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onPreferencesPressed,
    this.hasSyncErrors = false,
    this.isSyncing = false,
    required this.onSyncMetadata,
    required this.workspaces,
    required this.selectedWorkspace,
    required this.isWorkspaceLoading,
    required this.onWorkspaceSelected,
    required this.onManageWorkspaces,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.compactPaddingOnly(
        left: DesignTokens.space3,
        top: DesignTokens.space3,
        right: DesignTokens.space3,
        bottom: DesignTokens.space2,
      ),
      child: Row(
        children: [
          // App logo - in a gradient box matching tab bar height
          _LogoBox(),
          SizedBox(width: context.compactValue(12)),

          // Pill-style tab bar
          Expanded(
            child: _PillTabBar(
              selectedTab: selectedTab,
              onTabSelected: onTabSelected,
            ),
          ),

          SizedBox(width: context.compactValue(12)),

          // Workspace selector - pill style
          _PillWorkspaceSelector(
            workspaces: workspaces,
            selectedWorkspace: selectedWorkspace,
            isLoading: isWorkspaceLoading,
            onSelect: onWorkspaceSelected,
            onManage: onManageWorkspaces,
          ),

          SizedBox(width: context.compactValue(8)),

          // Sync button
          _SyncButton(
            onPressed: onSyncMetadata,
            isSyncing: isSyncing,
            hasSyncErrors: hasSyncErrors,
          ),

          SizedBox(width: context.compactValue(8)),

          // Settings/Preferences button
          _PreferencesButton(onPressed: onPreferencesPressed),
        ],
      ),
    );
  }
}

class _PillTabBar extends StatelessWidget {
  final LauncherTab selectedTab;
  final ValueChanged<LauncherTab> onTabSelected;

  const _PillTabBar({required this.selectedTab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(
          context.compactValue(DesignTokens.radiusMd),
        ),
      ),
      padding: EdgeInsets.all(context.compactValue(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillTab(
            label: 'Tools',
            isSelected: selectedTab == LauncherTab.tools,
            onTap: () => onTabSelected(LauncherTab.tools),
          ),
          _PillTab(
            label: 'Projects',
            isSelected: selectedTab == LauncherTab.projects,
            onTap: () => onTabSelected(LauncherTab.projects),
          ),
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final isDark = context.isDark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: context.compactValue(16),
            vertical: context.compactValue(8),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              context.compactValue(DesignTokens.radiusSm),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: context.compactValue(13),
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
                letterSpacing: 0.01,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  const _LogoBox();

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    // final brighterAccent = Color.lerp(accent, Colors.white, 0.7)!;
    final brighterAccent = accent;

    return Container(
      height: context.compactValue(50), // Match tab bar height
      width: context.compactValue(50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brighterAccent, accent],
        ),
        borderRadius: BorderRadius.circular(
          context.compactValue(DesignTokens.radiusMd),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(context.compactValue(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          context.compactValue(DesignTokens.radiusXs),
        ),
        child: Image.asset('assets/icon.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _PillWorkspaceSelector extends StatelessWidget {
  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final bool isLoading;
  final ValueChanged<String> onSelect;
  final VoidCallback onManage;

  const _PillWorkspaceSelector({
    required this.workspaces,
    required this.selectedWorkspace,
    required this.isLoading,
    required this.onSelect,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final accent = context.accentColor;

    if (isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.compactValue(12),
          vertical: context.compactValue(8),
        ),
        child: SizedBox(
          width: context.compactValue(16),
          height: context.compactValue(16),
          child: CircularProgressIndicator(strokeWidth: 2, color: accent),
        ),
      );
    }

    return AppMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      openOnHover: true,
      onSelected: (workspaceId) {
        if (workspaceId == '__manage__') {
          onManage();
        } else {
          onSelect(workspaceId);
        }
      },
      itemBuilder: (context) {
        final menuStyle = AppMenuStyle.of(context);
        final textStyle = menuStyle.textStyle;

        return [
          ...workspaces.map((workspace) {
            final isSelected = workspace.id == selectedWorkspace?.id;
            return PillMenuItem<String>(
              value: workspace.id,
              child: Row(
                children: [
                  Icon(
                    WorkspaceIcons.getIcon(workspace.iconIndex),
                    size: 16,
                    color: isSelected
                        ? accent
                        : menuStyle.resolveTextColor(true),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      workspace.name,
                      style: textStyle.copyWith(
                        color: isSelected
                            ? accent
                            : menuStyle.resolveTextColor(true),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected) Icon(Icons.check, size: 16, color: accent),
                ],
              ),
            );
          }),
          const PopupMenuDivider(),
          PillMenuItem<String>(
            value: '__manage__',
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 16,
                  color: menuStyle.resolveTextColor(true),
                ),
                const SizedBox(width: 10),
                Text(
                  'Manage workspaces',
                  style: textStyle.copyWith(
                    color: menuStyle.resolveTextColor(true),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(
            context.compactValue(DesignTokens.radiusMd),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.compactValue(12),
          vertical: context.compactValue(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedWorkspace != null)
              Icon(
                WorkspaceIcons.getIcon(selectedWorkspace!.iconIndex),
                size: context.compactValue(14),
                color: accent,
              ),
            if (selectedWorkspace != null)
              SizedBox(width: context.compactValue(6)),
            Text(
              selectedWorkspace?.name ?? 'Select workspace',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: context.compactValue(12),
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(width: context.compactValue(6)),
            Icon(
              Icons.keyboard_arrow_down,
              size: context.compactValue(16),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
