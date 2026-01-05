import 'package:flutter/material.dart';

class ProjectSectionHeader extends StatelessWidget {
  final String label;

  const ProjectSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor =
        theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface;
    final headerStyle =
        (theme.textTheme.labelLarge ?? theme.textTheme.bodyMedium)?.copyWith(
          color: baseColor.withOpacity(0.75),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(label, style: headerStyle),
    );
  }
}
