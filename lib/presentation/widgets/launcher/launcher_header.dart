import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final labelColor = textTheme.bodySmall!.color!.withValues(alpha: 0.75);

    // Reduced padding for minimal look
    return Container(
      padding: context.compactPaddingOnly(
        left: DesignTokens.space3,
        top: DesignTokens.space4 - 2,
        right: DesignTokens.space3,
        bottom: DesignTokens.space2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LauncherTabBar(
                    selectedTab: selectedTab,
                    onTabSelected: onTabSelected,
                  ),
                ),
              ),
              _WorkspaceSelector(
                workspaces: workspaces,
                selectedWorkspace: selectedWorkspace,
                isLoading: isWorkspaceLoading,
                onSelect: onWorkspaceSelected,
                onManage: onManageWorkspaces,
              ),
              SizedBox(width: context.compactValue(DesignTokens.space1 + 2)),
              _SyncButton(
                onPressed: onSyncMetadata,
                isSyncing: isSyncing,
                hasSyncErrors: hasSyncErrors,
              ),
              SizedBox(width: context.compactValue(DesignTokens.space2)),
              _PreferencesButton(onPressed: onPreferencesPressed),
            ],
          ),
          SizedBox(height: context.compactValue(DesignTokens.space2)),
          Text(
            selectedTab == LauncherTab.projects
                ? 'Projects toolbox'
                : 'Tools surface',
            style: textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.compactValue(1)),
          Text(
            selectedTab == LauncherTab.projects
                ? 'Search and open projects instantly'
                : 'Manage your preferred editors and utilities',
            style: textTheme.bodySmall!.copyWith(color: labelColor),
          ),
        ],
      ),
    );
  }
}
