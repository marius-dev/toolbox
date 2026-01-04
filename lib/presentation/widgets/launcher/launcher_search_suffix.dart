part of 'launcher_search_bar.dart';

enum _ActionMenuOption { addProject, importFromGit }

class _SearchFieldSuffix extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onClear;
  final bool showActions;
  final VoidCallback? onAddProject;
  final VoidCallback? onImportFromGit;
  final bool isMac;

  const _SearchFieldSuffix({
    required this.hasQuery,
    required this.onClear,
    required this.showActions,
    this.onAddProject,
    this.onImportFromGit,
    required this.isMac,
  });

  bool get _hasActions =>
      showActions && (onAddProject != null || onImportFromGit != null);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add button with gradient
          if (_hasActions)
            _GradientAddButton(
              onAddProject: onAddProject,
              onImportFromGit: onImportFromGit,
              isMac: isMac,
            ),
        ],
      ),
    );
  }
}

class _GradientAddButton extends StatefulWidget {
  final VoidCallback? onAddProject;
  final VoidCallback? onImportFromGit;
  final bool isMac;

  const _GradientAddButton({
    this.onAddProject,
    this.onImportFromGit,
    required this.isMac,
  });

  @override
  State<_GradientAddButton> createState() => _GradientAddButtonState();
}

class _GradientAddButtonState extends State<_GradientAddButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return AppMenuButton<_ActionMenuOption>(
      tooltip: 'Add new items',
      openOnHover: false,
      padding: EdgeInsets.zero,
      onSelected: (option) {
        switch (option) {
          case _ActionMenuOption.addProject:
            widget.onAddProject?.call();
            break;
          case _ActionMenuOption.importFromGit:
            widget.onImportFromGit?.call();
            break;
        }
      },
      itemBuilder: (context) {
        final menuStyle = AppMenuStyle.of(context);
        final textStyle = menuStyle.textStyle;
        Color resolveColor(bool enabled) => menuStyle.resolveTextColor(enabled);

        return [
          _ActionMenuOption.addProject,
          _ActionMenuOption.importFromGit,
        ].map((option) {
          bool enabled;
          IconData icon;
          String label;
          String? shortcut;
          switch (option) {
            case _ActionMenuOption.addProject:
              enabled = widget.onAddProject != null;
              icon = Icons.add_rounded;
              label = 'Add project';
              shortcut = widget.isMac ? '⌘N' : 'Ctrl+N';
              break;
            case _ActionMenuOption.importFromGit:
              enabled = widget.onImportFromGit != null;
              icon = Icons.download_rounded;
              label = 'Import from Git';
              break;
          }

          return PopupMenuItem<_ActionMenuOption>(
            value: option,
            enabled: enabled,
            child: Row(
              children: [
                Icon(icon, size: 18, color: resolveColor(enabled)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: textStyle.copyWith(color: resolveColor(enabled)),
                  ),
                ),
                if (shortcut != null)
                  Text(
                    shortcut,
                    style: textStyle.copyWith(
                      fontSize: 11,
                      color: resolveColor(enabled).withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor,
                accentColor.withValues(
                  red: (accentColor.r * 0.8).clamp(0, 1),
                  green: (accentColor.g * 0.8).clamp(0, 1),
                  blue: (accentColor.b * 0.8).clamp(0, 1),
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: _isHovered ? 0.4 : 0.3),
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.add, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
