part of 'project_item.dart';

class _MenuSectionHeader extends StatelessWidget {
  final String label;

  const _MenuSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.labelSmall ?? theme.textTheme.bodySmall;
    final headerStyle = baseStyle?.copyWith(
      color:
          (theme.textTheme.bodySmall?.color ??
                  theme.textTheme.bodyMedium?.color ??
                  Colors.white)
              .withOpacity(0.7),
      letterSpacing: 0.8,
      fontWeight: FontWeight.w700,
    );

    return SizedBox(
      height: CompactLayout.value(context, 30),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          CompactLayout.value(context, 12),
          CompactLayout.value(context, 6),
          CompactLayout.value(context, 12),
          CompactLayout.value(context, 4),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label.toUpperCase(), style: headerStyle),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: CompactLayout.value(context, 4)),
      color: Theme.of(context).dividerColor.withOpacity(0.35),
    );
  }
}

class _OpenWithSection extends StatelessWidget {
  final List<_MenuAction> toolActions;
  final void Function(_MenuAction) onAction;

  const _OpenWithSection({required this.toolActions, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (toolActions.isEmpty) {
      return _MenuActionTile(
        action: const _MenuAction(
          label: 'No supported tools installed',
          icon: Icons.block,
          onSelected: _noop,
          enabled: false,
        ),
        isMuted: true,
      );
    }

    return Scrollbar(
      radius: Radius.circular(CompactLayout.value(context, 5)),
      thickness: 4,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemCount: toolActions.length,
        itemBuilder: (context, index) => _MenuActionTile(
          action: toolActions[index],
          onPressed: () => onAction(toolActions[index]),
        ),
      ),
    );
  }
}

class _MenuAction {
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool enabled;
  final bool isDestructive;
  final String semanticsLabel;
  final Widget? leading;

  const _MenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.enabled = true,
    this.isDestructive = false,
    String? semanticsLabel,
    this.leading,
  }) : semanticsLabel = semanticsLabel ?? label;
}

class _MenuActionTile extends StatefulWidget {
  final _MenuAction action;
  final bool isMuted;
  final VoidCallback? onPressed;

  const _MenuActionTile({
    required this.action,
    this.isMuted = false,
    this.onPressed,
  });

  @override
  State<_MenuActionTile> createState() => _MenuActionTileState();
}

class _MenuActionTileState extends State<_MenuActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ThemeProvider.instance.accentColor;
    final baseColor = widget.action.isDestructive
        ? Colors.redAccent
        : theme.textTheme.bodyMedium?.color ??
              theme.textTheme.bodyLarge?.color ??
              Colors.white;
    final textColor = widget.isMuted
        ? baseColor.withOpacity(0.6)
        : widget.action.enabled
        ? baseColor
        : baseColor.withOpacity(0.5);

    return Semantics(
      label: widget.action.semanticsLabel,
      enabled: widget.action.enabled,
      button: true,
      child: GestureDetector(
        onTap: (widget.onPressed != null && widget.action.enabled)
            ? widget.onPressed
            : null,
        child: MouseRegion(
          cursor: widget.action.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Container(
            height: CompactLayout.value(
              context,
              _kProjectMenuActionTileBaseHeight,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: CompactLayout.value(context, 12),
            ),
            decoration: BoxDecoration(
              color: widget.action.enabled && _hovered
                  ? accent.withOpacity(0.08)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                if (widget.action.leading != null) ...[
                  widget.action.leading!,
                ] else ...[
                  Icon(
                    widget.action.icon,
                    size: CompactLayout.value(
                      context,
                      _kProjectMenuIconBaseSize,
                    ),
                    color: textColor,
                  ),
                ],
                SizedBox(width: CompactLayout.value(context, 10)),
                Expanded(
                  child: Text(
                    widget.action.label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: CompactLayout.value(
                        context,
                        _kProjectMenuTextBaseSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
