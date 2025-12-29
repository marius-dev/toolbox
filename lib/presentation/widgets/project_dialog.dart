import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/services/tool_discovery_service.dart';
import '../../core/services/window_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';
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
    final installed = tools.where((tool) => tool.isInstalled).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = ThemeProvider.instance.accentColor;
    final borderColor = theme.colorScheme.onSurface.withOpacity(
      isDark ? 0.12 : 0.08,
    );
    final background = Color.alphaBlend(
      isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
      theme.colorScheme.surface,
    );
    final isEditing = widget.project != null;

    return AlertDialog(
      backgroundColor: background,
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
            isEditing ? 'Edit Project' : 'Add Project',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: CompactLayout.value(context, 4)),
          Text(
            isEditing
                ? 'Adjust the metadata for this workspace'
                : 'Follow the quick steps to configure your new workspace',
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.textTheme.bodySmall!.color!.withOpacity(0.8),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: CompactLayout.value(context, 380),
        ),
        child: isEditing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.edit,
                  ),
                  SizedBox(height: CompactLayout.value(context, 12)),
                  _buildPathField(),
                  SizedBox(height: CompactLayout.value(context, 12)),
                  _buildTypeDropdown(),
                ],
              )
            : _buildWizardContent(context),
      ),
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
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(CompactLayout.value(context, 8)),
          ),
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
      width: CompactLayout.value(context, 430),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // _buildWizardProgress(context),
          // const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _currentStep == 0
                ? _buildFolderStep(context)
                : _currentStep == 1
                ? _buildNameStep(context)
                : _buildIdeStep(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderStep(BuildContext context) {
    return _buildPathField();
  }

  Widget _buildNameStep(BuildContext context) {
    return _buildTextField(
      controller: _nameController,
      label: 'Name',
      icon: Icons.edit,
    );
  }

  Widget _buildIdeStep(BuildContext context) {
    final mutedText = Theme.of(context).textTheme.bodySmall!.color!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = ThemeProvider.instance.accentColor;
    final basePanelColor = colorScheme.surface;
    final baseBorderColor = colorScheme.onSurface.withOpacity(
      isDark ? 0.08 : 0.06,
    );
    final highlightedColor = isDark
        ? Color.lerp(basePanelColor, Colors.white, 0.07)!
        : Color.lerp(basePanelColor, Colors.black, 0.07)!;

    final content = () {
      if (_isLoadingTools) {
        return SizedBox(
          height: CompactLayout.value(context, 110),
          child: Center(
            child: CircularProgressIndicator(
              color: ThemeProvider.instance.accentColor,
            ),
          ),
        );
      }

      if (_installedTools.isEmpty) {
        return Text(
          'No installed IDEs were detected. You can change the default tool later from the Tools tab.',
          style: theme.textTheme.bodySmall!.copyWith(
            color: mutedText.withOpacity(0.8),
          ),
        );
      }

      return SizedBox(
        height: CompactLayout.value(context, 200),
        child: ListView.builder(
          itemCount: _installedTools.length,
          itemBuilder: (context, index) {
            final tool = _installedTools[index];
            final isSelected = tool.id == _selectedToolId;
            final panelColor = isSelected ? highlightedColor : basePanelColor;
            final borderColor = isSelected
                ? accentColor.withOpacity(0.7)
                : baseBorderColor;

            return Container(
              margin: CompactLayout.only(
                context,
                bottom: 6,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    CompactLayout.value(context, 12),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedToolId = tool.id;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(CompactLayout.value(context, 10)),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(
                          CompactLayout.value(context, 12)),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        ToolIcon(
                          tool: tool,
                          size: CompactLayout.value(context, 28),
                          borderRadius: CompactLayout.value(context, 6),
                        ),
                        SizedBox(width: CompactLayout.value(context, 10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool.name,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: CompactLayout.value(context, 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: CompactLayout.value(context, 10)),
                        Radio<ToolId>(
                          value: tool.id,
                          groupValue: _selectedToolId,
                          activeColor: accentColor,
                          onChanged: (value) {
                            setState(() {
                              _selectedToolId = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }();

    return content;
  }

  Widget _buildStepCard(
    BuildContext context, {
    required String title,
    required String description,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.colorScheme.onSurface.withOpacity(
      isDark ? 0.12 : 0.08,
    );
    final background = Color.alphaBlend(
      isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
      theme.colorScheme.surface,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(CompactLayout.value(context, 14)),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          CompactLayout.value(context, 16),
        ),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: CompactLayout.value(context, 4)),
          Text(
            description,
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.textTheme.bodySmall!.color!.withOpacity(0.75),
            ),
          ),
          SizedBox(height: CompactLayout.value(context, 12)),
          child,
        ],
      ),
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
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(CompactLayout.value(context, 8)),
          ),
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
      label: 'Path',
      icon: Icons.folder_open,
      suffix: IconButton(
        icon: Icon(
          Icons.folder_outlined,
          color: Theme.of(context).iconTheme.color,
          size: CompactLayout.value(context, 18),
        ),
        splashRadius: CompactLayout.value(context, 16),
        onPressed: _pickProjectFolder,
        tooltip: 'Pick folder',
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.95);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);
    final dropdownBg = Theme.of(context).colorScheme.surface;

    return DropdownButtonFormField<ProjectType>(
      initialValue: _selectedType,
      dropdownColor: dropdownBg,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        prefixIcon: Icon(
          Icons.category,
          color: Theme.of(context).iconTheme.color,
        ),
        filled: true,
        fillColor: panelColor,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CompactLayout.value(context, 10)),
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
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.96);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);
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
          borderRadius:
              BorderRadius.circular(CompactLayout.value(context, 10)),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CompactLayout.value(context, 10)),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(CompactLayout.value(context, 10)),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
    );
  }
}
