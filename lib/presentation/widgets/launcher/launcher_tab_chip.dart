part of 'launcher_tab_bar.dart';

class _ModeChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final inactiveColor = textColor.withOpacity(0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: CompactLayout.value(context, 14),
          vertical: CompactLayout.value(context, 6),
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isActive ? accent : Colors.transparent,
          border: Border.all(
            color: isActive ? accent : textColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: CompactLayout.value(context, 14),
              color: isActive ? Colors.white : inactiveColor,
            ),
            SizedBox(width: CompactLayout.value(context, 6)),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : inactiveColor,
                fontSize: CompactLayout.value(context, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
