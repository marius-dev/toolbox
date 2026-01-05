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
      color: menuStyle.textStyle.color!.withValues(alpha: 0.5),
      fontSize: 10,
      letterSpacing: 0.6,
      fontWeight: FontWeight.w600,
    );

    return SizedBox(
      height: context.compactValue(22), // More compact
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.compactValue(12),
          context.compactValue(4),
          context.compactValue(12),
          context.compactValue(2),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: context.compactValue(4)),
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06),
    );
  }
}

/// A scrollable list of menu actions with a scrollbar
class _ScrollableActionList extends StatelessWidget {
  final List<_MenuAction> actions;
  final void Function(_MenuAction) onAction;
  final String? emptyMessage;

  const _ScrollableActionList({
    required this.actions,
    required this.onAction,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return _MenuActionTile(
        action: _MenuAction(
          label: emptyMessage ?? 'No items',
          icon: Icons.block,
          onSelected: _noop,
          enabled: false,
        ),
        isMuted: true,
        indented: true,
      );
    }

    return Scrollbar(
      radius: Radius.circular(context.compactValue(4)),
      thickness: 3,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (context, index) => _MenuActionTile(
          action: actions[index],
          onPressed: () => onAction(actions[index]),
          indented: true,
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
  final bool indented;
  final VoidCallback? onPressed;

  const _MenuActionTile({
    required this.action,
    this.isMuted = false,
    this.indented = false,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.action.isDestructive
        ? Colors.redAccent
        : menuStyle.textStyle.color!;
    final disabledColor = widget.action.isDestructive
        ? baseColor.withValues(alpha: 0.5)
        : menuStyle.mutedTextStyle.color!;
    final textColor = widget.isMuted
        ? baseColor.withValues(alpha: 0.6)
        : widget.action.enabled
        ? baseColor
        : disabledColor;

    // Indented items have more left padding
    final leftPadding = widget.indented
        ? context.compactValue(20)
        : context.compactValue(12);

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
            height: context.compactValue(_kProjectMenuActionTileBaseHeight),
            padding: EdgeInsets.only(
              left: leftPadding,
              right: context.compactValue(12),
            ),
            decoration: BoxDecoration(
              color: widget.action.enabled && _hovered
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05))
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                if (widget.action.leading != null) ...[
                  widget.action.leading!,
                ] else ...[
                  Icon(
                    widget.action.icon,
                    size: context.compactValue(_kProjectMenuIconBaseSize),
                    color: textColor,
                  ),
                ],
                SizedBox(width: context.compactValue(10)),
                Expanded(
                  child: Text(
                    widget.action.label,
                    style: menuStyle.textStyle.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
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
