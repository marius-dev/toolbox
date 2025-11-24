import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/string_utils.dart';

enum OpenWithApp { vscode, intellij, preview }

class ProjectItem extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onStarToggle;
  final VoidCallback onShowInFinder;
  final void Function(OpenWithApp app) onOpenWith;
  final VoidCallback onDelete;

  const ProjectItem({
    Key? key,
    required this.project,
    required this.onTap,
    required this.onStarToggle,
    required this.onShowInFinder,
    required this.onOpenWith,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = !project.pathExists;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: panelColor.withOpacity(isDisabled ? 0.7 : 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                _buildAvatar(context, isDisabled),
                const SizedBox(width: 12),
                Expanded(child: _buildInfo(context, isDisabled)),
                const SizedBox(width: 8),
                _buildStarButton(context),
                _buildActions(context, isDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isDisabled) {
    final accentColor = ThemeProvider.instance.accentColor;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? LinearGradient(
                colors: [Colors.grey.shade800, Colors.grey.shade700],
              )
            : LinearGradient(colors: [_lighten(accentColor, 0.1), accentColor]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          project.name.substring(0, 2).toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool isDisabled) {
    final textPrimary = Theme.of(context).textTheme.bodyLarge!.color!;
    final mutedText = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.4)
        : Colors.black45;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: TextStyle(
                  color: isDisabled ? mutedText : textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (isDisabled) _buildNotFoundBadge(),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 12, color: mutedText),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                StringUtils.ellipsisStart(project.path, maxLength: 45),
                style: TextStyle(color: mutedText, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotFoundBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Not Found',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStarButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        project.isStarred ? Icons.star : Icons.star_border,
        color: project.isStarred
            ? Colors.amber
            : Theme.of(context).iconTheme.color,
        size: 18,
      ),
      onPressed: onStarToggle,
    );
  }

  Widget _buildActions(BuildContext context, bool isDisabled) {
    if (isDisabled) {
      return IconButton(
        icon: const Icon(Icons.close, color: Colors.red, size: 18),
        onPressed: onDelete,
        tooltip: 'Remove',
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A1F3D) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        color: Theme.of(context).iconTheme.color,
        size: 18,
      ),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'show_finder',
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 18),
              const SizedBox(width: 8),
              Text('Show in Finder', style: TextStyle(color: textColor)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Hide from the toolbox (delete)',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Section header: Open with
        const PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'Open with',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        PopupMenuItem<String>(
          value: 'open_vscode',
          child: Row(
            children: [
              const Icon(Icons.code, size: 18),
              const SizedBox(width: 8),
              Text('VS Code', style: TextStyle(color: textColor)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'open_intellij',
          child: Row(
            children: [
              const Icon(Icons.terminal, size: 18),
              const SizedBox(width: 8),
              Text('IntelliJ', style: TextStyle(color: textColor)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'open_preview',
          child: Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined, size: 18),
              const SizedBox(width: 8),
              Text('Preview', style: TextStyle(color: textColor)),
            ],
          ),
        ),
      ],
      onSelected: (String value) {
        switch (value) {
          case 'show_finder':
            onShowInFinder();
            break;
          case 'delete':
            onDelete();
            break;
          case 'open_vscode':
            onOpenWith(OpenWithApp.vscode);
            break;
          case 'open_intellij':
            onOpenWith(OpenWithApp.intellij);
            break;
          case 'open_preview':
            onOpenWith(OpenWithApp.preview);
            break;
        }
      },
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
