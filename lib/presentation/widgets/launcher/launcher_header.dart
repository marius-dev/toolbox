import 'package:flutter/material.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/compact_layout.dart';
import '../../../domain/models/workspace.dart';
import '../app_menu.dart';
import 'launcher_tab_bar.dart';

part 'launcher_header_buttons.dart';

class LauncherHeader extends StatelessWidget {
  final LauncherTab selectedTab;
  final ValueChanged<LauncherTab> onTabSelected;
  final VoidCallback onSettingsPressed;
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
    required this.onSettingsPressed,
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
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final textTheme = Theme.of(context).textTheme;
        final labelColor = textTheme.bodySmall!.color!.withOpacity(0.8);

        return Container(
          padding: CompactLayout.only(
            context,
            left: 10,
            top: 16,
            right: 10,
            bottom: 8,
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
                  SizedBox(width: CompactLayout.value(context, 6)),
                  _SyncButton(
                    onPressed: onSyncMetadata,
                    isSyncing: isSyncing,
                    hasSyncErrors: hasSyncErrors,
                  ),
                  SizedBox(width: CompactLayout.value(context, 8)),
                  _SettingsButton(onPressed: onSettingsPressed),
                ],
              ),
              SizedBox(height: CompactLayout.value(context, 10)),
              Text(
                selectedTab == LauncherTab.projects
                    ? 'Projects toolbox'
                    : 'Tools surface',
                style: textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: CompactLayout.value(context, 2)),
              Text(
                selectedTab == LauncherTab.projects
                    ? 'Search and open projects instantly'
                    : 'Manage your preferred editors and utilities',
                style: textTheme.bodySmall!.copyWith(color: labelColor),
              ),
            ],
          ),
        );
      },
    );
  }
}
