import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/models/project.dart';
import '../../core/theme/theme_provider.dart';

class ProjectDialog extends StatefulWidget {
  final Project? project;
  final Function(String name, String path, ProjectType type) onSave;

  const ProjectDialog({Key? key, this.project, required this.onSave})
    : super(key: key);

  @override
  State<ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _pathController;
  late ProjectType _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _pathController = TextEditingController(text: widget.project?.path ?? '');
    _selectedType = widget.project?.type ?? ProjectType.flutter;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _pickProjectFolder() async {
    final selectedPath = await FilePicker.platform.getDirectoryPath();
    if (selectedPath != null) {
      setState(() => _pathController.text = selectedPath);
    }
  }

  void _save() {
    if (_nameController.text.isNotEmpty && _pathController.text.isNotEmpty) {
      widget.onSave(_nameController.text, _pathController.text, _selectedType);
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
      content: Column(
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
      ),
      actions: [
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
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
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
      value: _selectedType,
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
