import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/theme_extensions.dart';

import '../../core/di/service_locator.dart';
import '../../core/services/tool_discovery_service.dart';
import '../../core/services/window_service.dart';
import '../../core/theme/glass_style.dart';
import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import 'tool_icon.dart';

class ProjectDialog extends StatefulWidget {
  final Project? project;
  final ToolId? defaultToolId;
  final Future<void> Function(String name, String path, ToolId? preferredToolId)
  onSave;

  const ProjectDialog({
    super.key,
    this.project,
    this.defaultToolId,
    required this.onSave,
  });

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  late final WindowService _windowService;
  late final ToolDiscoveryService _toolDiscoveryService;
  late TextEditingController _nameController;
  late TextEditingController _pathController;
  bool _isLoadingTools = false;
  List<Tool> _installedTools = [];
  ToolId? _selectedToolId;

  @override
  void initState() {
    super.initState();
    _windowService = getIt<WindowService>();
    _toolDiscoveryService = getIt<ToolDiscoveryService>();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _pathController = TextEditingController(text: widget.project?.path ?? '');
    _loadInstalledTools();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickProjectFolder() async {
    final selectedPath = await _windowService.runWithAutoHideSuppressed(
      () => FilePicker.platform.getDirectoryPath(),
    );
    if (selectedPath != null) {
      setState(() {
        _pathController.text = selectedPath;
        if (widget.project == null && _nameController.text.isEmpty) {
          _nameController.text = _extractFolderName(selectedPath);
        }
      });
    }
  }

  Future<void> _loadInstalledTools() async {
    setState(() => _isLoadingTools = true);

    final tools = await _toolDiscoveryService.discoverTools();
    final installed = tools.where((tool) => tool.isInstalled).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    ToolId? initialId;
    final preferredToolId =
        widget.project?.lastUsedToolId ?? widget.defaultToolId;
    if (preferredToolId != null &&
        installed.any((tool) => tool.id == preferredToolId)) {
      initialId = preferredToolId;
    } else if (installed.isNotEmpty) {
      initialId = installed.first.id;
    }

    if (!mounted) return;
    setState(() {
      _installedTools = installed;
      _selectedToolId = initialId;
      _isLoadingTools = false;
    });
  }

  String _extractFolderName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    if (segments.isEmpty) return path;
    return segments.last.isEmpty && segments.length > 1
        ? segments[segments.length - 2]
        : segments.last;
  }

  bool get _canSave {
    if (_pathController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty) {
      return false;
    }
    if (_isLoadingTools) return false;
    if (_installedTools.isNotEmpty && _selectedToolId == null) {
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final preferredToolId = _selectedToolId ?? widget.project?.lastUsedToolId;
    await widget.onSave(
      _nameController.text.trim(),
      _pathController.text.trim(),
      preferredToolId,
    );
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _selectTool(Tool tool) {
    setState(() => _selectedToolId = tool.id);
  }

  InputDecoration _buildSearchFieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? hint,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = theme.textTheme.bodyLarge!.color!;
    final fillColor = isDark
        ? Colors.black.withOpacity(0.45)
        : Colors.white.withOpacity(0.92);
    final borderColor = baseColor.withOpacity(isDark ? 0.3 : 0.16);
    final accentColor = context.accentColor;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: theme.textTheme.bodyMedium,
      prefixIcon: Icon(icon, color: theme.iconTheme.color, size: 20),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentColor, width: 1.4),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? Colors.black.withOpacity(0.5)
        : Colors.white.withOpacity(0.9);
    final borderColor = theme.dividerColor.withOpacity(0.24);
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(context.compactValue(20)),
      border: Border.all(color: borderColor),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      decoration: _cardDecoration(context),
      padding: EdgeInsets.all(context.compactValue(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPathField(context),
          SizedBox(height: context.compactValue(12)),
          _buildNameField(context),
        ],
      ),
    );
  }

  Widget _buildToolsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: _cardDecoration(context),
      padding: EdgeInsets.all(context.compactValue(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred tool',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: context.compactValue(12)),
          _buildToolsList(context),
        ],
      ),
    );
  }

  Widget _buildPathField(BuildContext context) {
    return TextField(
      controller: _pathController,
      readOnly: true,
      onTap: _pickProjectFolder,
      decoration: _buildSearchFieldDecoration(
        context,
        label: 'Project folder',
        icon: Icons.folder_open,
        hint: 'Select a folder',
      ),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildNameField(BuildContext context) {
    return TextField(
      controller: _nameController,
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() {}),
      decoration: _buildSearchFieldDecoration(
        context,
        label: 'Project name',
        icon: Icons.edit_note_rounded,
        hint: 'Name your project',
      ),
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }

  Widget _buildToolsList(BuildContext context) {
    if (_isLoadingTools) {
      return SizedBox(
        height: context.compactValue(100),
        child: Center(
          child: CircularProgressIndicator(color: context.accentColor),
        ),
      );
    }

    if (_installedTools.isEmpty) {
      return Text(
        'No IDEs were detected. You can add one later from the Tools tab.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: context.compactValue(220)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _installedTools.length; i++) ...[
              _buildToolOption(context, _installedTools[i]),
              if (i < _installedTools.length - 1)
                SizedBox(height: context.compactValue(8)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolOption(BuildContext context, Tool tool) {
    final theme = Theme.of(context);
    final accentColor = context.accentColor;
    final isSelected = tool.id == _selectedToolId;
    final background = isSelected
        ? accentColor.withOpacity(
            theme.brightness == Brightness.dark ? 0.2 : 0.12,
          )
        : Colors.transparent;
    final borderColor = isSelected
        ? accentColor.withOpacity(0.7)
        : theme.dividerColor.withOpacity(
            theme.brightness == Brightness.dark ? 0.4 : 0.2,
          );

    return InkWell(
      borderRadius: BorderRadius.circular(context.compactValue(14)),
      onTap: () => _selectTool(tool),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.compactValue(12),
          vertical: context.compactValue(10),
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(context.compactValue(14)),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            ToolIcon(tool: tool, size: context.compactValue(28)),
            SizedBox(width: context.compactValue(10)),
            Expanded(child: Text(tool.name, style: theme.textTheme.bodyLarge)),
            Radio<ToolId>(
              value: tool.id,
              groupValue: _selectedToolId,
              onChanged: (_) => _selectTool(tool),
              activeColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(Color accentColor, bool isEditing) {
    final theme = Theme.of(context);
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Cancel',
          style: TextStyle(color: theme.textTheme.bodyMedium!.color),
        ),
      ),
      ElevatedButton(
        onPressed: _canSave ? _save : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentColor.withOpacity(0.3),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.compactValue(8)),
          ),
        ),
        child: Text(
          isEditing ? 'Save' : 'Add',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = context.accentColor;
    final palette = GlassStylePalette(
      style: context.glassStyle,
      isDark: theme.brightness == Brightness.dark,
      accentColor: accentColor,
    );
    final borderColor = palette.borderColor;
    final background = solidDialogBackground(palette, theme);
    final isEditing = widget.project != null;

    return AlertDialog(
      backgroundColor: background,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.compactValue(28),
        vertical: context.compactValue(18),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.compactValue(22)),
        side: BorderSide(color: borderColor),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        context.compactValue(24),
        context.compactValue(18),
        context.compactValue(24),
        0,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        context.compactValue(24),
        context.compactValue(14),
        context.compactValue(24),
        context.compactValue(10),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        context.compactValue(18),
        0,
        context.compactValue(18),
        context.compactValue(12),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Edit Project' : 'Add Project',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: context.compactValue(4)),
          Text(
            isEditing
                ? 'Adjust the metadata for this project'
                : 'Follow the quick steps to configure your new project',
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.textTheme.bodySmall!.color!.withOpacity(0.8),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(minWidth: context.compactValue(380)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFormCard(context),
              SizedBox(height: context.compactValue(14)),
              _buildToolsCard(context),
            ],
          ),
        ),
      ),
      actions: _buildActions(accentColor, isEditing),
    );
  }
}
