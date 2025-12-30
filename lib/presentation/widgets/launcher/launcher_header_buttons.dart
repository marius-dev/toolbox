part of 'launcher_header.dart';

class _StatusIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;

  const _StatusIcon({
    required this.tooltip,
    required this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ThemeProvider.instance.accentColor;
    final baseColor = Theme.of(context).iconTheme.color!;
    final background = Theme.of(context).cardColor.withOpacity(0.25);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 120),
      child: Container(
        width: CompactLayout.value(context, 34),
        height: CompactLayout.value(context, 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive ? accent.withOpacity(0.16) : background,
          border: Border.all(
            color: isActive
                ? accent.withOpacity(0.7)
                : baseColor.withOpacity(0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: CompactLayout.value(context, 14),
          color: isActive ? accent : baseColor,
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
