part of 'project_item.dart';

class _MenuSectionHeader extends StatelessWidget {
  final String label;

  const _MenuSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final menuStyle = AppMenuStyle.of(context);
    final baseStyle =
        theme.textTheme.labelSmall ??
        theme.textTheme.bodySmall ??
        menuStyle.textStyle;
    final headerStyle = baseStyle.copyWith(
      color: menuStyle.textStyle.color!.withOpacity(0.7),
      letterSpacing: 0.8,
      fontWeight: FontWeight.w700,
    );

    return SizedBox(
      height: context.compactValue(30),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.compactValue(12),
          context.compactValue(6),
          context.compactValue(12),
          context.compactValue(4),
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
      margin: EdgeInsets.symmetric(vertical: context.compactValue(4)),
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
      radius: Radius.circular(context.compactValue(5)),
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
    final menuStyle = AppMenuStyle.of(context);
    final accent = context.accentColor;
    final baseColor = widget.action.isDestructive
        ? Colors.redAccent
        : menuStyle.textStyle.color!;
    final disabledColor = widget.action.isDestructive
        ? baseColor.withOpacity(0.5)
        : menuStyle.mutedTextStyle.color!;
    final textColor = widget.isMuted
        ? baseColor.withOpacity(0.6)
        : widget.action.enabled
        ? baseColor
        : disabledColor;

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
            height: context.compactValue(
              _kProjectMenuActionTileBaseHeight,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.compactValue(12),
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
                    size: context.compactValue(
                      _kProjectMenuIconBaseSize,
                    ),
                    color: textColor,
                  ),
                ],
                SizedBox(width: context.compactValue(10)),
                Expanded(
                  child: Text(
                    widget.action.label,
                    style: menuStyle.textStyle.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
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
