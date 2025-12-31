part of 'launcher_header.dart';

enum _WorkspaceMenuActionType { select, manage }

class _WorkspaceMenuAction {
  final _WorkspaceMenuActionType type;
  final String? workspaceId;

  const _WorkspaceMenuAction.select(this.workspaceId)
    : type = _WorkspaceMenuActionType.select;
  const _WorkspaceMenuAction.manage()
    : type = _WorkspaceMenuActionType.manage,
      workspaceId = null;
}

class _WorkspaceSelector extends StatelessWidget {
  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final bool isLoading;
  final ValueChanged<String> onSelect;
  final VoidCallback onManage;

  const _WorkspaceSelector({
    required this.workspaces,
    required this.selectedWorkspace,
    required this.isLoading,
    required this.onSelect,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ThemeProvider.instance.accentColor;
    final baseColor = Theme.of(context).iconTheme.color!;
    final background = Theme.of(context).cardColor.withOpacity(0.25);
    final label = isLoading
        ? 'Loading...'
        : selectedWorkspace?.name ?? 'No workspace';
    final labelColor = isLoading ? baseColor.withOpacity(0.6) : baseColor;
    final menuStyle = AppMenuStyle.of(context);

    return AppMenuButton<_WorkspaceMenuAction>(
      tooltip: 'Switch workspace',
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action.type) {
          case _WorkspaceMenuActionType.select:
            if (action.workspaceId != null) {
              onSelect(action.workspaceId!);
            }
            break;
          case _WorkspaceMenuActionType.manage:
            onManage();
            break;
        }
      },
      itemBuilder: (context) {
        final textStyle = menuStyle.textStyle;
        final baseTextColor = textStyle.color!;
        Color resolveColor(bool enabled) => menuStyle.resolveTextColor(enabled);

        final items = <PopupMenuEntry<_WorkspaceMenuAction>>[];

        for (final workspace in workspaces) {
          final isSelected = selectedWorkspace?.id == workspace.id;
          items.add(
            PopupMenuItem<_WorkspaceMenuAction>(
              value: _WorkspaceMenuAction.select(workspace.id),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_rounded : Icons.layers_rounded,
                    size: 16,
                    color: isSelected ? accent : baseTextColor,
                  ),
                  SizedBox(width: CompactLayout.value(context, 8)),
                  SizedBox(
                    width: CompactLayout.value(context, 160),
                    child: Text(
                      workspace.name,
                      style: textStyle.copyWith(
                        color: baseTextColor,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (workspaces.isNotEmpty) {
          items.add(const PopupMenuDivider());
        }

        items.add(
          PopupMenuItem<_WorkspaceMenuAction>(
            value: const _WorkspaceMenuAction.manage(),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: resolveColor(true)),
                const SizedBox(width: 10),
                Text(
                  'Manage workspaces',
                  style: textStyle.copyWith(color: resolveColor(true)),
                ),
              ],
            ),
          ),
        );

        return items;
      },
      child: Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: CompactLayout.value(context, 10),
          ),
          height: CompactLayout.value(context, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: background,
            border: Border.all(color: baseColor.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.layers_rounded,
                size: CompactLayout.value(context, 14),
                color: labelColor,
              ),
              SizedBox(width: CompactLayout.value(context, 6)),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: CompactLayout.value(context, 120),
                ),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: CompactLayout.value(context, 4)),
              Icon(
                Icons.expand_more_rounded,
                size: CompactLayout.value(context, 16),
                color: labelColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isSyncing;
  final bool hasSyncErrors;

  const _SyncButton({
    required this.onPressed,
    required this.isSyncing,
    required this.hasSyncErrors,
  });

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isSyncing) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _SyncButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing == oldWidget.isSyncing) return;
    if (widget.isSyncing) {
      _rotationController.repeat();
    } else {
      _rotationController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = ThemeProvider.instance.accentColor;
    final baseColor = Theme.of(context).iconTheme.color!;
    final background = Theme.of(context).cardColor.withOpacity(0.25);
    final isBusy = widget.isSyncing;
    final hasIssues = widget.hasSyncErrors;
    final borderColor = baseColor.withOpacity(0.2);
    final iconColor = isBusy ? accent : baseColor;
    final tooltip = isBusy
        ? 'Syncing projects metadata...'
        : hasIssues
        ? 'Sync projects metadata (missing paths)'
        : 'Sync projects metadata';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 120),
      child: InkWell(
        onTap: isBusy ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: CompactLayout.value(context, 34),
          height: CompactLayout.value(context, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isBusy ? accent.withOpacity(0.16) : background,
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: RotationTransition(
            turns: _rotationController,
            child: Icon(
              Icons.sync_rounded,
              size: CompactLayout.value(context, 14),
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SettingsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final accent = ThemeProvider.instance.accentColor;
    return Tooltip(
      message: 'Preferences (⌘,)',
      waitDuration: const Duration(milliseconds: 120),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: CompactLayout.value(context, 34),
          height: CompactLayout.value(context, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.4)),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.settings_rounded,
            size: CompactLayout.value(context, 14),
            color: accent,
          ),
        ),
      ),
    );
  }
}
