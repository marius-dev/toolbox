part of 'launcher_tab_bar.dart';

class _ModeChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color accent;
  final Color textColor;

  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.accent,
    required this.textColor,
  });

  @override
  State<_ModeChip> createState() => _ModeChipState();
}

class _ModeChipState extends State<_ModeChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = widget.textColor.withValues(alpha: 0.65);

    // Hover effect for inactive chips
    final backgroundColor = widget.isActive
        ? widget.accent
        : _isHovered
        ? widget.accent.withValues(alpha: 0.12)
        : Colors.transparent;

    final borderColor = widget.isActive
        ? widget.accent
        : _isHovered
        ? widget.accent.withValues(alpha: 0.3)
        : widget.textColor.withValues(alpha: 0.2);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: AnimatedContainer(
          duration: GlassTransitions.hoverDuration,
          curve: GlassTransitions.hoverCurve,
          padding: EdgeInsets.symmetric(
            horizontal: context.compactValue(DesignTokens.space4 - 2),
            vertical: context.compactValue(DesignTokens.space1 + 2),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            color: backgroundColor,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: context.compactValue(DesignTokens.iconSm),
                color: widget.isActive ? Colors.white : inactiveColor,
              ),
              SizedBox(width: context.compactValue(DesignTokens.space1 + 2)),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isActive ? Colors.white : inactiveColor,
                  fontSize: context.compactValue(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
