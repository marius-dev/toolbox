import 'dart:ui';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../core/services/window_service.dart';
import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';
import '../../domain/models/tool.dart';
import '../providers/project_provider.dart';
import '../providers/tools_provider.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_panel.dart';
import '../widgets/tool_icon.dart';

class AddProjectScreen extends StatefulWidget {
  final ProjectProvider projectProvider;
  final ToolsProvider toolsProvider;
  final String workspaceId;

  const AddProjectScreen({
    super.key,
    required this.projectProvider,
    required this.toolsProvider,
    required this.workspaceId,
  });

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  final FocusNode _pathFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _introController;

  ToolId? _selectedToolId;
  List<Tool> _installedTools = [];
  bool _isLoadingTools = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..forward();

    _pathController.addListener(_handlePathInput);
    _syncTools(triggerDiscovery: true);
    widget.toolsProvider.addListener(_handleToolsChanged);
    ThemeProvider.instance.addListener(_handleThemeChanged);
  }

  @override
  void dispose() {
    ThemeProvider.instance.removeListener(_handleThemeChanged);
    widget.toolsProvider.removeListener(_handleToolsChanged);
    _introController.dispose();
    _nameController.dispose();
    _pathController.dispose();
    _scrollController.dispose();
    _pathFocus.dispose();
    super.dispose();
  }

  void _handleToolsChanged() {
    _syncTools();
  }

  void _handleThemeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handlePathInput() {
    if (_nameController.text.isEmpty && _pathController.text.isNotEmpty) {
      final folderName = _extractFolderName(_pathController.text.trim());
      _nameController
        ..text = folderName
        ..selection = TextSelection.collapsed(offset: folderName.length);
    }
    setState(() {});
  }

  void _syncTools({bool triggerDiscovery = false}) {
    final installed = widget.toolsProvider.installed;

    if (triggerDiscovery &&
        installed.isEmpty &&
        !widget.toolsProvider.isLoading) {
      widget.toolsProvider.loadTools();
    }

    ToolId? selected = _selectedToolId;

    if (installed.isEmpty) {
      selected = null;
    } else {
      final defaultId = widget.toolsProvider.defaultToolId;
      final hasSelected =
          selected != null && installed.any((tool) => tool.id == selected);

      if (!hasSelected) {
        if (defaultId != null &&
            installed.any((tool) => tool.id == defaultId)) {
          selected = defaultId;
        } else {
          selected = installed.first.id;
        }
      }
    }

    setState(() {
      _installedTools = installed;
      _selectedToolId = selected;
      _isLoadingTools = widget.toolsProvider.isLoading;
    });
  }

  Duration _animationDuration(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceAnimations =
        media.disableAnimations || media.accessibleNavigation;
    return reduceAnimations
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 360);
  }

  Curve _animationCurve(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceAnimations =
        media.disableAnimations || media.accessibleNavigation;
    return reduceAnimations ? Curves.linear : Curves.easeOutCubic;
  }

  bool get _canSave {
    if (_isSaving) return false;
    if (_pathController.text.trim().isEmpty) return false;
    if (_nameController.text.trim().isEmpty) return false;
    if (_isLoadingTools) return false;
    if (_installedTools.isNotEmpty && _selectedToolId == null) return false;
    return true;
  }

  Future<void> _pickFolder() async {
    final selectedPath = await WindowService.instance.runWithAutoHideSuppressed(
      () => FilePicker.platform.getDirectoryPath(),
    );
    if (selectedPath != null) {
      _pathController.text = selectedPath;
      _announce('Selected folder $selectedPath');
    }
  }

  String _extractFolderName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    if (segments.isEmpty) return path;
    return segments.last.isEmpty && segments.length > 1
        ? segments[segments.length - 2]
        : segments.last;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    final preferredToolId =
        _selectedToolId ?? widget.toolsProvider.defaultToolId;

    await widget.projectProvider.addProject(
      name: _nameController.text.trim(),
      path: _pathController.text.trim(),
      preferredToolId: preferredToolId,
      workspaceId: widget.workspaceId,
    );

    if (!mounted) return;
    _announce('Added ${_nameController.text}');
    Navigator.of(context).pop(true);
  }

  void _announce(String message) {
    final direction = Directionality.of(context);
    SemanticsService.announce(message, direction);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ThemeProvider.instance.accentColor;
    final palette = GlassStylePalette.fromContext(
      context,
      style: ThemeProvider.instance.glassStyle,
      accentColor: accentColor,
    );
    final duration = _animationDuration(context);
    final curve = _animationCurve(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.backgroundGradient,
          ),
          border: Border.all(color: palette.borderColor),
          boxShadow: palette.shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: palette.blurSigma,
              sigmaY: palette.blurSigma,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackdrop(palette),
                SafeArea(
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _introController,
                      curve: curve,
                    ),
                    child: _buildContent(context, duration, curve, palette),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackdrop(GlassStylePalette palette) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(top: -120, left: -40, child: _glow(palette.glowColor, 260)),
        Positioned(
          bottom: -180,
          right: -60,
          child: _glow(palette.glowColor.withOpacity(0.7), 340),
        ),
      ],
    );
  }

  Widget _glow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Duration duration,
    Curve curve,
    GlassStylePalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: CompactLayout.only(context, top: 40, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: CompactLayout.symmetric(context, horizontal: 18),
                  child: _buildHeader(context),
                ),
                SizedBox(height: CompactLayout.value(context, 12)),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: CompactLayout.only(context, bottom: 12),
                      child: Padding(
                        padding: CompactLayout.symmetric(
                          context,
                          horizontal: 18,
                        ),
                        child: _buildForm(context, palette),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: CompactLayout.only(context, top: 0, bottom: 0),
          child: _buildBottomBar(context, duration, curve),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodyMedium!.color!.withOpacity(0.8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Back to launcher',
          child: GlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        SizedBox(width: CompactLayout.value(context, 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a project',
                style: textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: CompactLayout.value(context, 4)),
              Text(
                'Choose the folder, name it, and set a preferred tool.',
                style: textTheme.bodyMedium!.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Duration duration, Curve curve) {
    final accentColor = ThemeProvider.instance.accentColor;

    return GlassPanel(
      duration: duration,
      curve: curve,
      padding: EdgeInsets.symmetric(
        horizontal: CompactLayout.value(context, 18),
        vertical: CompactLayout.value(context, 14),
      ),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(CompactLayout.value(context, 20)),
      ),
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [_buildSaveActionButton(context, accentColor)],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    required GlassStylePalette palette,
    Widget? suffix,
  }) {
    final panelColor = palette.innerColor;
    final borderColor = palette.borderColor;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: panelColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 12)),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 12)),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 12)),
        borderSide: BorderSide(
          color: ThemeProvider.instance.accentColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, GlassStylePalette palette) {
    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            context,
            'Project details',
            subtitle: 'Select the folder and assign a working name.',
          ),
          SizedBox(height: CompactLayout.value(context, 16)),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = CompactLayout.value(context, 18);
              final isWide = constraints.maxWidth >= 640;
              final columnWidth = isWide
                  ? (constraints.maxWidth - spacing) / 2
                  : double.infinity;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: columnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildPathField(context, palette)],
                    ),
                  ),
                  SizedBox(
                    width: columnWidth,
                    child: _buildTextField(
                      context: context,
                      controller: _nameController,
                      label: 'Project name',
                      icon: Icons.edit_note_rounded,
                      palette: palette,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: CompactLayout.value(context, 32)),
          _buildSectionHeader(context, 'Preferred tool'),
          SizedBox(height: CompactLayout.value(context, 20)),
          _buildToolsList(context),
        ],
      ),
    );
  }

  Widget _buildPathField(BuildContext context, GlassStylePalette palette) {
    return TextField(
      controller: _pathController,
      focusNode: _pathFocus,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(
        context,
        label: 'Project folder',
        icon: Icons.folder_open_rounded,
        suffix: Tooltip(
          message: 'Browse for a folder',
          child: IconButton(
            icon: const Icon(Icons.manage_search),
            onPressed: _pickFolder,
          ),
        ),
        palette: palette,
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required GlassStylePalette palette,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
      decoration: _inputDecoration(
        context,
        label: label,
        icon: icon,
        palette: palette,
      ),
    );
  }

  Widget _buildToolsList(BuildContext context) {
    final accentColor = ThemeProvider.instance.accentColor;
    if (_isLoadingTools) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: CompactLayout.value(context, 18),
        ),
        child: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (_installedTools.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: CompactLayout.value(context, 10),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: accentColor),
            SizedBox(width: CompactLayout.value(context, 8)),
            Expanded(
              child: Text(
                'No installed IDEs detected. You can still save and update later from Tools.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: _animationDuration(context),
      child: ListView.separated(
        key: ValueKey(_installedTools.length),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _installedTools.length,
        separatorBuilder: (_, __) =>
            SizedBox(height: CompactLayout.value(context, 8)),
        itemBuilder: (context, index) {
          final tool = _installedTools[index];
          final selected = _selectedToolId == tool.id;
          return Material(
            color: Colors.transparent,
            child: Semantics(
              selected: selected,
              button: true,
              label: 'Launch with ${tool.name}',
              child: RadioListTile<ToolId>(
                value: tool.id,
                groupValue: _selectedToolId,
                activeColor: accentColor,
                onChanged: (value) {
                  setState(() => _selectedToolId = value);
                  _announce('${tool.name} selected');
                },
                title: Row(
                  children: [
                    ToolIcon(
                      tool: tool,
                      size: CompactLayout.value(context, 26),
                    ),
                    SizedBox(width: CompactLayout.value(context, 10)),
                    Text(tool.name),
                  ],
                ),
                subtitle: tool.isInstalled
                    ? const Text('Installed and ready')
                    : const Text('Not installed'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    String? subtitle,
  }) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          SizedBox(height: CompactLayout.value(context, 4)),
          Text(subtitle, style: theme.bodySmall),
        ],
      ],
    );
  }

  Widget _buildSaveActionButton(BuildContext context, Color accentColor) {
    final isEnabled = _canSave;
    final isBusy = _isSaving;
    final showActive = isEnabled || isBusy;
    final gradientColors = showActive
        ? [accentColor.withOpacity(0.95), accentColor.withOpacity(0.85)]
        : [accentColor.withOpacity(0.45), accentColor.withOpacity(0.65)];
    final borderColor = showActive
        ? Colors.white.withOpacity(0.5)
        : Colors.white.withOpacity(0.2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? _save : null,
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 14)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(
              CompactLayout.value(context, 14),
            ),
            border: Border.all(color: borderColor),
            boxShadow: showActive
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: CompactLayout.value(context, 20),
            vertical: CompactLayout.value(context, 14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Save',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
