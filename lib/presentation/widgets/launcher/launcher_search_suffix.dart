part of 'launcher_search_bar.dart';

enum _ActionMenuOption { addProject, importFromGit, createWorkspace }

class _SearchFieldSuffix extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onClear;
  final bool showActions;
  final VoidCallback? onAddProject;
  final VoidCallback? onImportFromGit;
  final VoidCallback? onCreateWorkspace;

  const _SearchFieldSuffix({
    required this.hasQuery,
    required this.onClear,
    required this.showActions,
    this.onAddProject,
    this.onImportFromGit,
    this.onCreateWorkspace,
  });

  bool get _hasActions =>
      showActions &&
      (onAddProject != null ||
          onImportFromGit != null ||
          onCreateWorkspace != null);

  @override
  Widget build(BuildContext context) {
    if (!hasQuery && !_hasActions) {
      return const SizedBox.shrink();
    }

    final iconColor =
        Theme.of(context).iconTheme.color?.withOpacity(0.8) ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasQuery)
            IconButton(
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(Icons.close_rounded, color: iconColor),
              onPressed: onClear,
            ),
          if (hasQuery && _hasActions) const SizedBox(width: 4),
          if (_hasActions)
            _InlineActionMenuButton(
              onAddProject: onAddProject,
              onImportFromGit: onImportFromGit,
              onCreateWorkspace: onCreateWorkspace,
            ),
        ],
      ),
    );
  }
}

class _InlineActionMenuButton extends StatelessWidget {
  final VoidCallback? onAddProject;
  final VoidCallback? onImportFromGit;
  final VoidCallback? onCreateWorkspace;

  const _InlineActionMenuButton({
    this.onAddProject,
    this.onImportFromGit,
    this.onCreateWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor =
        theme.iconTheme.color?.withOpacity(0.85) ?? Colors.grey.shade700;

    return PopupMenuButton<_ActionMenuOption>(
      tooltip: 'Create or import a workspace',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (option) {
        switch (option) {
          case _ActionMenuOption.addProject:
            onAddProject?.call();
            break;
          case _ActionMenuOption.importFromGit:
            onImportFromGit?.call();
            break;
          case _ActionMenuOption.createWorkspace:
            onCreateWorkspace?.call();
            break;
        }
      },
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.bodyMedium!;
        final baseColor =
            textStyle.color ?? Theme.of(context).colorScheme.onSurface;
        Color resolveColor(bool enabled) =>
            enabled ? baseColor : baseColor.withOpacity(0.4);

        return [
          _ActionMenuOption.addProject,
          _ActionMenuOption.importFromGit,
          _ActionMenuOption.createWorkspace,
        ].map((option) {
          bool enabled;
          IconData icon;
          String label;
          switch (option) {
            case _ActionMenuOption.addProject:
              enabled = onAddProject != null;
              icon = Icons.add_rounded;
              label = 'Add project';
              break;
            case _ActionMenuOption.importFromGit:
              enabled = onImportFromGit != null;
              icon = Icons.download_rounded;
              label = 'Import from Git';
              break;
            case _ActionMenuOption.createWorkspace:
              enabled = onCreateWorkspace != null;
              icon = Icons.layers_rounded;
              label = 'Create workspace';
              break;
          }

          return PopupMenuItem<_ActionMenuOption>(
            value: option,
            enabled: enabled,
            child: Row(
              children: [
                Icon(icon, size: 18, color: resolveColor(enabled)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: textStyle.copyWith(color: resolveColor(enabled)),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 6, right: 12, top: 6, bottom: 6),
        child: Icon(Icons.menu_rounded, size: 20, color: iconColor),
      ),
    );
  }
}
