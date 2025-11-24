import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/services/tool_discovery_service.dart';
import '../../core/services/window_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import 'tool_icon.dart';

class ProjectDialog extends StatefulWidget {
  final Project? project;
  final ToolId? defaultToolId;
  final Function(
    String name,
    String path,
    ProjectType type,
    ToolId? preferredToolId,
  )
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
  late TextEditingController _nameController;
  late TextEditingController _pathController;
  late ProjectType _selectedType;
  int _currentStep = 0;
  bool _isLoadingTools = false;
  List<Tool> _installedTools = [];
  ToolId? _selectedToolId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _pathController = TextEditingController(text: widget.project?.path ?? '');
    _selectedType = widget.project?.type ?? ProjectType.flutter;

    if (widget.project == null) {
      _loadInstalledTools();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickProjectFolder() async {
    final selectedPath = await WindowService.instance.runWithAutoHideSuppressed(
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
    setState(() {
      _isLoadingTools = true;
    });

    final tools = await ToolDiscoveryService.instance.discoverTools();
    final installed =
        tools
            .where((tool) => tool.isInstalled && tool.id != ToolId.preview)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    ToolId? initialId;
    if (widget.project?.lastUsedToolId != null &&
        installed.any((t) => t.id == widget.project!.lastUsedToolId)) {
      initialId = widget.project!.lastUsedToolId;
    } else if (widget.defaultToolId != null &&
        installed.any((t) => t.id == widget.defaultToolId)) {
      initialId = widget.defaultToolId;
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

  void _save() {
    if (_nameController.text.isNotEmpty && _pathController.text.isNotEmpty) {
      final preferredToolId = widget.project == null
          ? _selectedToolId
          : widget.project?.lastUsedToolId;
      widget.onSave(
        _nameController.text,
        _pathController.text,
        _selectedType,
        preferredToolId,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A1F3D) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.06);
    final accentColor = ThemeProvider.instance.accentColor;

    final isEditing = widget.project != null;

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      title: Text(
        widget.project == null ? 'Add Project' : 'Edit Project',
        style: Theme.of(
          context,
        ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
      ),
      content: isEditing
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Project Name',
                  icon: Icons.edit,
                ),
                const SizedBox(height: 16),
                _buildPathField(),
                const SizedBox(height: 16),
                _buildTypeDropdown(),
              ],
            )
          : _buildWizardContent(context),
      actions: isEditing
          ? _buildEditActions(accentColor)
          : _buildWizardActions(accentColor),
    );
  }

  List<Widget> _buildEditActions(Color accentColor) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Cancel',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
        ),
      ),
      ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Save',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    ];
  }

  Widget _buildWizardContent(BuildContext context) {
    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentStep == 0) _buildFolderStep(context),
          if (_currentStep == 1) _buildNameStep(context),
          if (_currentStep == 2) _buildIdeStep(context),
        ],
      ),
    );
  }

  Widget _buildFolderStep(BuildContext context) {
    final mutedText = Theme.of(context).textTheme.bodySmall!.color!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPathField(),
        const SizedBox(height: 8),
        Text(
          'Choose the folder that contains your project.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: mutedText.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildNameStep(BuildContext context) {
    final mutedText = Theme.of(context).textTheme.bodySmall!.color!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Project Name',
          icon: Icons.edit,
        ),
        const SizedBox(height: 8),
        Text(
          'We prefilled this from the folder name, but you can change it.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: mutedText.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildIdeStep(BuildContext context) {
    final mutedText = Theme.of(context).textTheme.bodySmall!.color!;

    if (_isLoadingTools) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: ThemeProvider.instance.accentColor,
          ),
        ),
      );
    }

    if (_installedTools.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferred IDE',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'No installed IDEs were detected. You can change the default tool later from the Tools tab.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: mutedText.withOpacity(0.8)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred IDE',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.builder(
            itemCount: _installedTools.length,
            itemBuilder: (context, index) {
              final tool = _installedTools[index];
              return RadioListTile<ToolId>(
                value: tool.id,
                groupValue: _selectedToolId,
                onChanged: (value) {
                  setState(() {
                    _selectedToolId = value;
                  });
                },
                title: Text(tool.name),
                subtitle: Text(
                  tool.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: ToolIcon(tool: tool, size: 28, borderRadius: 6),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWizardActions(Color accentColor) {
    final canContinue = _canContinueFromStep();
    final isLastStep = _currentStep == 2;

    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Cancel',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
        ),
      ),
      if (_currentStep > 0)
        TextButton(
          onPressed: () {
            setState(() {
              _currentStep = (_currentStep - 1).clamp(0, 2);
            });
          },
          child: const Text('Back'),
        ),
      ElevatedButton(
        onPressed: canContinue
            ? () {
                if (isLastStep) {
                  _save();
                } else {
                  setState(() {
                    _currentStep = (_currentStep + 1).clamp(0, 2);
                  });
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentColor.withOpacity(0.3),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          isLastStep ? 'Save' : 'Next',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ];
  }

  bool _canContinueFromStep() {
    switch (_currentStep) {
      case 0:
        return _pathController.text.isNotEmpty;
      case 1:
        return _nameController.text.isNotEmpty;
      case 2:
        if (_isLoadingTools) return false;
        if (_installedTools.isEmpty) return true;
        return _selectedToolId != null;
      default:
        return false;
    }
  }

  Widget _buildPathField() {
    return _buildTextField(
      controller: _pathController,
      label: 'Project Path',
      icon: Icons.folder_open,
      suffix: IconButton(
        icon: Icon(
          Icons.folder_outlined,
          color: Theme.of(context).iconTheme.color,
        ),
        splashRadius: 18,
        onPressed: _pickProjectFolder,
        tooltip: 'Pick folder',
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.95);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.06);
    final dropdownBg = isDark ? const Color(0xFF2A1F3D) : Colors.white;

    return DropdownButtonFormField<ProjectType>(
      initialValue: _selectedType,
      dropdownColor: dropdownBg,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: 'Project Type',
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        prefixIcon: Icon(
          Icons.category,
          color: Theme.of(context).iconTheme.color,
        ),
        filled: true,
        fillColor: panelColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
      items: ProjectType.values.map((type) {
        return DropdownMenuItem(value: type, child: Text(type.displayName));
      }).toList(),
      onChanged: (type) {
        if (type != null) setState(() => _selectedType = type);
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.95);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.06);
    final accentColor = ThemeProvider.instance.accentColor;

    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        prefixIcon: Icon(icon, color: Theme.of(context).iconTheme.color),
        suffixIcon: suffix,
        filled: true,
        fillColor: panelColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
    );
  }
}
