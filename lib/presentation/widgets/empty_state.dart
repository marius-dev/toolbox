import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onAddProject;

  const EmptyState({super.key, required this.onAddProject});

  @override
  Widget build(BuildContext context) {
    final mutedText = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.4)
        : Colors.black45;
    final textSecondary = Theme.of(context).textTheme.bodyMedium!.color!;
    final accentColor = ThemeProvider.instance.accentColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: mutedText),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: TextStyle(color: textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAddProject,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Project'),
            style: TextButton.styleFrom(foregroundColor: accentColor),
          ),
        ],
      ),
    );
  }
}
