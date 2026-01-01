import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';
import '../../domain/models/workspace.dart';

class WorkspaceDialog extends StatefulWidget {
  final Workspace? workspace;

  const WorkspaceDialog({super.key, this.workspace});

  @override
  State<WorkspaceDialog> createState() => _WorkspaceDialogState();
}

class _WorkspaceDialogState extends State<WorkspaceDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: _limitName(widget.workspace?.name ?? ''),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = ThemeProvider.instance.accentColor;
    final palette = GlassStylePalette(
      style: ThemeProvider.instance.glassStyle,
      isDark: theme.brightness == Brightness.dark,
      accentColor: accentColor,
    );
    final borderColor = palette.borderColor;
    final background = solidDialogBackground(palette, theme);
    final fieldFill = _solidFieldFill(theme, background);
    final isEditing = widget.workspace != null;
    final canSave = _nameController.text.trim().isNotEmpty;
    final nameLength = _nameController.text.length;
    final isLimitReached = nameLength >= Workspace.maxNameLength;

    return AlertDialog(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: CompactLayout.value(context, 28),
        vertical: CompactLayout.value(context, 18),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 22)),
        side: BorderSide(color: borderColor),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        CompactLayout.value(context, 24),
        CompactLayout.value(context, 18),
        CompactLayout.value(context, 24),
        0,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        CompactLayout.value(context, 24),
        CompactLayout.value(context, 14),
        CompactLayout.value(context, 24),
        CompactLayout.value(context, 10),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        CompactLayout.value(context, 18),
        0,
        CompactLayout.value(context, 18),
        CompactLayout.value(context, 12),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Edit workspace' : 'Create workspace',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: CompactLayout.value(context, 4)),
          Text(
            isEditing
                ? 'Rename your workspace to keep it organized.'
                : 'Give your workspace a name to group related projects.',
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.textTheme.bodySmall!.color!.withOpacity(0.8),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: CompactLayout.value(context, 360),
        ),
        child: TextField(
          controller: _nameController,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          inputFormatters: [
            LengthLimitingTextInputFormatter(Workspace.maxNameLength),
          ],
          decoration: InputDecoration(
            labelText: 'Workspace name',
            prefixIcon: const Icon(Icons.layers_rounded),
            filled: true,
            fillColor: fieldFill,
            helperText: isLimitReached
                ? 'Max ${Workspace.maxNameLength} characters reached'
                : null,
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                CompactLayout.value(context, 10),
              ),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                CompactLayout.value(context, 10),
              ),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                CompactLayout.value(context, 10),
              ),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.textTheme.bodyMedium!.color),
          ),
        ),
        ElevatedButton(
          onPressed: canSave ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: accentColor.withOpacity(0.3),
            disabledForegroundColor: Colors.white.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                CompactLayout.value(context, 8),
              ),
            ),
          ),
          child: Text(
            isEditing ? 'Save' : 'Create',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

String _limitName(String name) {
  final trimmed = name.trim();
  if (trimmed.length <= Workspace.maxNameLength) {
    return trimmed;
  }
  return trimmed.substring(0, Workspace.maxNameLength).trimRight();
}

class WorkspaceDeleteDialog extends StatelessWidget {
  final String workspaceName;

  const WorkspaceDeleteDialog({super.key, required this.workspaceName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = ThemeProvider.instance.accentColor;
    final palette = GlassStylePalette(
      style: ThemeProvider.instance.glassStyle,
      isDark: theme.brightness == Brightness.dark,
      accentColor: accentColor,
    );
    final borderColor = palette.borderColor;
    final background = solidDialogBackground(palette, theme);

    return AlertDialog(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: CompactLayout.value(context, 28),
        vertical: CompactLayout.value(context, 18),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 22)),
        side: BorderSide(color: borderColor),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        CompactLayout.value(context, 24),
        CompactLayout.value(context, 18),
        CompactLayout.value(context, 24),
        0,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        CompactLayout.value(context, 24),
        CompactLayout.value(context, 14),
        CompactLayout.value(context, 24),
        CompactLayout.value(context, 10),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        CompactLayout.value(context, 18),
        0,
        CompactLayout.value(context, 18),
        CompactLayout.value(context, 12),
      ),
      title: Text('Remove workspace?', style: theme.textTheme.titleLarge),
      content: Text(
        'Projects in "$workspaceName" will be moved to another workspace.',
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.textTheme.bodySmall!.color!.withOpacity(0.8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.textTheme.bodyMedium!.color),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                CompactLayout.value(context, 8),
              ),
            ),
          ),
          child: const Text(
            'Remove',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

Color _solidFieldFill(ThemeData theme, Color background) {
  final overlay = theme.brightness == Brightness.dark
      ? Colors.white.withOpacity(0.04)
      : Colors.black.withOpacity(0.02);
  return Color.alphaBlend(overlay, background);
}
