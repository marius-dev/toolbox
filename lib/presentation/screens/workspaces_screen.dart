import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_extensions.dart';

import '../../core/constants/workspace_icons.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/window_service.dart';
import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import '../../domain/models/workspace.dart';
import '../providers/project_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/glass_action_button.dart';
import '../widgets/glass_panel.dart';
import '../widgets/launcher/project_list_scroll_behavior.dart';
import '../widgets/section_layout.dart';
import '../widgets/workspace_dialog.dart';
import 'launcher/launcher_intents.dart';

class WorkspacesScreen extends StatefulWidget {
  final WorkspaceProvider workspaceProvider;
  final ProjectProvider projectProvider;

  const WorkspacesScreen({
    super.key,
    required this.workspaceProvider,
    required this.projectProvider,
  });

  @override
  State<WorkspacesScreen> createState() => _WorkspacesScreenState();
}

class _WorkspacesScreenState extends State<WorkspacesScreen>
    with SingleTickerProviderStateMixin {
  static const int _workspaceExportVersion = 1;

  late final AnimationController _introController;
  late final WindowService _windowService;
  final ScrollController _scrollController = ScrollController();

  // Batch selection state
  final Set<String> _selectedWorkspaceIds = {};

  bool get _hasSelection => _selectedWorkspaceIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _windowService = getIt<WindowService>();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _createWorkspace() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const WorkspaceDialog(),
    );
    if (result == null) return;
    final name = (result['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return;
    final iconIndex = result['iconIndex'] as int?;
    await widget.workspaceProvider.createWorkspace(name, iconIndex: iconIndex);
  }

  Future<void> _renameWorkspace(Workspace workspace) async {
    // Allow renaming all workspaces
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => WorkspaceDialog(workspace: workspace),
    );
    if (result == null) return;
    final name = (result['name'] as String?)?.trim();
    if (name == null || name.isEmpty) return;
    final iconIndex = result['iconIndex'] as int?;
    await widget.workspaceProvider.renameWorkspace(workspace, name, iconIndex: iconIndex);
  }

  Future<void> _deleteWorkspace(Workspace workspace) async {
    // Prevent deletion of the last remaining workspace
    if (!widget.workspaceProvider.canDeleteWorkspace) {
      _showMessage('Cannot delete the last workspace');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          WorkspaceDeleteDialog(workspaceName: workspace.name),
    );
    if (confirmed != true) return;
    await widget.workspaceProvider.deleteWorkspace(workspace.id);
    if (!mounted) return;
    final newWorkspaceId = widget.workspaceProvider.selectedWorkspaceId;
    if (newWorkspaceId != null && newWorkspaceId.isNotEmpty) {
      widget.projectProvider.setWorkspaceId(newWorkspaceId);
      await widget.projectProvider.reassignWorkspace(
        fromWorkspaceId: workspace.id,
        toWorkspaceId: newWorkspaceId,
      );
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    // Adjust newIndex if moving down the list
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final workspaces = List<Workspace>.from(widget.workspaceProvider.workspaces);
    final workspace = workspaces.removeAt(oldIndex);
    workspaces.insert(newIndex, workspace);

    // Update order for all workspaces
    await widget.workspaceProvider.reorderWorkspaces(workspaces);
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final elevation = animation.value * 8.0;
        return Material(
          elevation: elevation,
          color: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          child: child,
        );
      },
      child: child,
    );
  }

  void _toggleWorkspaceSelection(String workspaceId) {
    setState(() {
      if (_selectedWorkspaceIds.contains(workspaceId)) {
        _selectedWorkspaceIds.remove(workspaceId);
      } else {
        _selectedWorkspaceIds.add(workspaceId);
      }
    });
  }

  void _selectAllWorkspaces() {
    setState(() {
      _selectedWorkspaceIds.clear();
      _selectedWorkspaceIds.addAll(
        widget.workspaceProvider.workspaces.map((w) => w.id),
      );
    });
  }

  void _deselectAllWorkspaces() {
    setState(() {
      _selectedWorkspaceIds.clear();
    });
  }

  Future<void> _batchDeleteWorkspaces() async {
    if (_selectedWorkspaceIds.isEmpty) return;

    // Check if deleting would leave no workspaces
    final remainingCount = widget.workspaceProvider.workspaces.length - _selectedWorkspaceIds.length;
    if (remainingCount < 1) {
      _showMessage('Cannot delete all workspaces. At least one must remain.');
      return;
    }

    final count = _selectedWorkspaceIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _BatchDeleteConfirmDialog(count: count),
    );

    if (confirmed != true) return;

    // Delete selected workspaces
    for (final id in _selectedWorkspaceIds.toList()) {
      await widget.workspaceProvider.deleteWorkspace(id);
    }

    if (!mounted) return;
    _showMessage('Deleted $count workspace${count > 1 ? 's' : ''}');

    // Clear selection after deletion
    setState(() {
      _selectedWorkspaceIds.clear();
    });

    // Update project provider with new workspace
    final newWorkspaceId = widget.workspaceProvider.selectedWorkspaceId;
    if (newWorkspaceId != null) {
      widget.projectProvider.setWorkspaceId(newWorkspaceId);
    }
  }

  Future<void> _exportWorkspace(Workspace workspace) async {
    final projects = widget.projectProvider.allProjects
        .where((project) => project.workspaceId == workspace.id)
        .toList();
    final payload = {
      'version': _workspaceExportVersion,
      'workspace': workspace.toJson(),
      'projects': projects.map((project) => project.toJson()).toList(),
    };

    final suggestedName = '${_sanitizeFileName(workspace.name)}.json';
    final outputPath = await _windowService.runWithAutoHideSuppressed(
      () => FilePicker.platform.saveFile(
        dialogTitle: 'Export workspace',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
      ),
    );
    if (outputPath == null || outputPath.isEmpty) return;

    final resolvedPath = outputPath.toLowerCase().endsWith('.json')
        ? outputPath
        : '$outputPath.json';
    try {
      final encoder = const JsonEncoder.withIndent('  ');
      await File(resolvedPath).writeAsString(encoder.convert(payload));
    } catch (_) {
      _showMessage('Failed to export workspace');
      return;
    }

    _showMessage('Exported ${workspace.name}');
  }

  Future<void> _importWorkspace() async {
    final result = await _windowService.runWithAutoHideSuppressed(
      () => FilePicker.platform.pickFiles(
        dialogTitle: 'Import workspace',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      ),
    );
    if (result == null || result.files.isEmpty) return;
    final selectedPath = result.files.single.path;
    if (selectedPath == null || selectedPath.isEmpty) return;

    final contents = await _readJsonFile(selectedPath);
    if (contents == null) {
      _showMessage('Unable to read workspace file');
      return;
    }

    final decoded = _decodeJson(contents);
    if (decoded == null) {
      _showMessage('Invalid workspace file');
      return;
    }

    final workspaceName = _extractWorkspaceName(decoded);
    if (workspaceName == null || workspaceName.trim().isEmpty) {
      _showMessage('Workspace file is missing a name');
      return;
    }

    final createdWorkspace = await widget.workspaceProvider.createWorkspace(
      workspaceName.trim(),
    );

    final projects = _parseProjects(decoded);
    final importedCount = await widget.projectProvider.importProjects(
      workspaceId: createdWorkspace.id,
      projects: projects,
    );

    if (!mounted) return;
    await widget.workspaceProvider.setSelectedWorkspace(createdWorkspace.id);
    widget.projectProvider.setWorkspaceId(createdWorkspace.id);

    final suffix = importedCount == 1 ? '1 project' : '$importedCount projects';
    final message = importedCount > 0
        ? 'Imported ${createdWorkspace.name} ($suffix)'
        : 'Imported ${createdWorkspace.name}';
    _showMessage(message);
  }

  String _sanitizeFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'workspace';
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<String?> _readJsonFile(String path) async {
    try {
      return await File(path).readAsString();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decodeJson(String contents) {
    try {
      final decoded = json.decode(contents);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  String? _extractWorkspaceName(Map<String, dynamic> decoded) {
    final workspaceJson = _mapFromJson(decoded['workspace']);
    final name = workspaceJson?['name'] ?? decoded['name'];
    return name is String ? name : null;
  }

  List<Project> _parseProjects(Map<String, dynamic> decoded) {
    final raw = decoded['projects'];
    if (raw is! List) return [];
    final projects = <Project>[];
    for (final entry in raw) {
      final jsonMap = _mapFromJson(entry);
      if (jsonMap == null) continue;
      final parsed = _projectFromJson(jsonMap);
      if (parsed != null) {
        projects.add(parsed);
      }
    }
    return projects;
  }

  Map<String, dynamic>? _mapFromJson(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  Project? _projectFromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final path = json['path'];
    if (name is! String || name.trim().isEmpty) return null;
    if (path is! String || path.trim().isEmpty) return null;

    final now = DateTime.now();
    final createdAt = _parseDate(
      json['createdAt'],
      fallback: _parseDate(json['lastOpened'], fallback: now),
    );
    final lastOpened = _parseDate(json['lastOpened'], fallback: createdAt);

    final idValue = json['id'];
    final id = idValue is String && idValue.isNotEmpty
        ? idValue
        : now.millisecondsSinceEpoch.toString();

    ToolId? lastUsedToolId;
    final toolValue = json['lastUsedToolId'];
    if (toolValue is String && toolValue.isNotEmpty) {
      try {
        lastUsedToolId = ToolId.values.firstWhere(
          (tool) => tool.name == toolValue,
        );
      } catch (_) {}
    }

    final gitInfo = ProjectGitInfo.fromJson(
      json['gitInfo'] is Map<String, dynamic>
          ? json['gitInfo'] as Map<String, dynamic>
          : json['gitInfo'] is Map
          ? Map<String, dynamic>.from(json['gitInfo'] as Map)
          : null,
    );

    return Project(
      id: id,
      name: name.trim(),
      path: path.trim(),
      workspaceId: json['workspaceId'] is String
          ? json['workspaceId'] as String
          : null,
      isStarred: json['isStarred'] == true,
      lastOpened: lastOpened,
      createdAt: createdAt,
      lastUsedToolId: lastUsedToolId,
      gitInfo: gitInfo,
    );
  }

  DateTime _parseDate(dynamic value, {required DateTime fallback}) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return fallback;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _animationDuration(context);
    final curve = _animationCurve(context);
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    final shortcuts = <ShortcutActivator, Intent>{
      // Workspace switching shortcuts (Cmd/Ctrl + 1-9)
      for (var i = 1; i <= 9; i++)
        SingleActivator(
          LogicalKeyboardKey(0x00000030 + i), // Key codes for 1-9
          control: !isMac,
          meta: isMac,
        ): SwitchWorkspaceIntent(i - 1),
      // Create workspace shortcut
      SingleActivator(LogicalKeyboardKey.keyN, control: !isMac, meta: isMac):
          const CreateWorkspaceIntent(),
      // Delete workspace shortcut
      SingleActivator(
        LogicalKeyboardKey.backspace,
        control: !isMac,
        meta: isMac,
      ): const DeleteWorkspaceIntent(),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          SwitchWorkspaceIntent: CallbackAction<SwitchWorkspaceIntent>(
            onInvoke: (intent) async {
              final workspaces = widget.workspaceProvider.workspaces;
              if (intent.index < workspaces.length) {
                final workspace = workspaces[intent.index];
                await widget.workspaceProvider.setSelectedWorkspace(workspace.id);
                widget.projectProvider.setWorkspaceId(workspace.id);
              }
              return null;
            },
          ),
          CreateWorkspaceIntent: CallbackAction<CreateWorkspaceIntent>(
            onInvoke: (intent) {
              _createWorkspace();
              return null;
            },
          ),
          DeleteWorkspaceIntent: CallbackAction<DeleteWorkspaceIntent>(
            onInvoke: (intent) {
              final selected = widget.workspaceProvider.selectedWorkspace;
              if (selected != null && widget.workspaceProvider.canDeleteWorkspace) {
                _deleteWorkspace(selected);
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: _handleEscapeKey,
          child: AppShell(
            blurSigma: 40,
            builder: (context, _) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: _introController, curve: curve),
                child: _buildContent(context, duration, curve),
              );
            },
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleEscapeKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildContent(BuildContext context, Duration duration, Curve curve) {
    final horizontalPadding = context.compactPadding(horizontal: 18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: context.compactPaddingOnly(top: 40),
            child: SectionLayout(
              onBack: () => Navigator.of(context).maybePop(),
              title: 'Manage workspaces',
              subtitle: 'Create, rename, and organize your workspaces.',
              padding: horizontalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bulk actions bar - appears when items are selected
                  if (_hasSelection)
                    Container(
                      margin: context.compactPaddingOnly(bottom: 16),
                      padding: EdgeInsets.all(context.compactValue(16)),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedWorkspaceIds.length} workspace${_selectedWorkspaceIds.length > 1 ? 's' : ''} selected',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _batchDeleteWorkspaces,
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: context.compactValue(18),
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                label: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                              SizedBox(width: context.compactValue(8)),
                              TextButton(
                                onPressed: _deselectAllWorkspaces,
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Expanded(child: _buildWorkspaceList(context)),
                  SizedBox(height: context.compactValue(12)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: context.compactPaddingOnly(top: 0, bottom: 0),
          child: _buildBottomBar(context, duration, curve),
        ),
      ],
    );
  }

  Widget _buildWorkspaceList(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.workspaceProvider,
      builder: (context, _) {
        if (widget.workspaceProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.accentColor),
          );
        }
        final workspaces = widget.workspaceProvider.workspaces;
        final selectedId = widget.workspaceProvider.selectedWorkspaceId;
        final theme = Theme.of(context);
        final isDark = context.isDark;
        final background = isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.9);
        final borderColor = theme.dividerColor.withValues(alpha: 0.16);

        return Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              children: [
                // Select All header row
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.compactValue(16),
                    vertical: context.compactValue(8),
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Align checkbox with drag handle position
                      SizedBox(
                        width: context.compactValue(18),
                        child: Transform.scale(
                          scale: 0.85,
                          child: Checkbox(
                            value: _selectedWorkspaceIds.length == workspaces.length &&
                                workspaces.isNotEmpty,
                            onChanged: (_) {
                              if (_selectedWorkspaceIds.length == workspaces.length) {
                                _deselectAllWorkspaces();
                              } else {
                                _selectAllWorkspaces();
                              }
                            },
                            activeColor: context.accentColor,
                          ),
                        ),
                      ),
                      SizedBox(width: context.compactValue(12)),
                      Text(
                        'Select All',
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: context.compactValue(13),
                          color: theme.textTheme.bodySmall!.color!.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const ProjectListScrollBehavior(),
                    child: Scrollbar(
                      controller: _scrollController,
                      radius: const Radius.circular(6),
                      thickness: 4,
                      child: ReorderableListView.builder(
                        scrollController: _scrollController,
                        padding: EdgeInsets.zero,
                        buildDefaultDragHandles: false,
                        onReorder: _onReorder,
                        proxyDecorator: _proxyDecorator,
                        itemCount: workspaces.length,
                        itemBuilder: (context, index) {
                          final workspace = workspaces[index];
                          final projectCount = widget.projectProvider.allProjects
                              .where((p) => p.workspaceId == workspace.id)
                              .length;
                          return _WorkspaceRow(
                            key: ValueKey(workspace.id),
                            workspace: workspace,
                            index: index,
                            isActive: workspace.id == selectedId,
                            canDelete: widget.workspaceProvider.canDeleteWorkspace,
                            isChecked: _selectedWorkspaceIds.contains(workspace.id),
                            projectCount: projectCount,
                            onExport: _exportWorkspace,
                            onRename: _renameWorkspace,
                            onDelete: _deleteWorkspace,
                            onToggleSelection: () => _toggleWorkspaceSelection(workspace.id),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                // Footer hint
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: context.compactValue(12),
                  ),
                  child: Center(
                    child: Text(
                      'Drag items to reorder • Click checkbox to select',
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontSize: context.compactValue(11),
                        color: theme.textTheme.bodySmall!.color!.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, Duration duration, Curve curve) {
    final isDark = context.isDark;
    final bottomColor = isDark ? Colors.black.withValues(alpha: 0.42) : null;

    return GlassPanel(
      duration: duration,
      curve: curve,
      padding: EdgeInsets.symmetric(
        horizontal: context.compactValue(18),
        vertical: context.compactValue(14),
      ),
      borderRadius: BorderRadius.zero,
      margin: EdgeInsets.zero,
      backgroundColor: bottomColor,
      isTransparent: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [_buildActionGroup(context)],
      ),
    );
  }

  Widget _buildActionGroup(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildImportButton(context),
        SizedBox(width: context.compactValue(10)),
        _buildCreateButton(context),
      ],
    );
  }

  Widget _buildImportButton(BuildContext context) {
    return GlassActionButton(
      label: 'Import',
      icon: Icons.upload_file_rounded,
      onPressed: _importWorkspace,
      primary: false,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return GlassActionButton(
      label: 'Create',
      icon: Icons.add_rounded,
      onPressed: _createWorkspace,
      primary: true,
    );
  }
}

class _WorkspaceRow extends StatefulWidget {
  final Workspace workspace;
  final int index;
  final bool isActive;
  final bool canDelete;
  final bool isChecked;
  final int projectCount;
  final Future<void> Function(Workspace) onExport;
  final Future<void> Function(Workspace) onRename;
  final Future<void> Function(Workspace) onDelete;
  final VoidCallback onToggleSelection;

  const _WorkspaceRow({
    super.key,
    required this.workspace,
    required this.index,
    required this.isActive,
    required this.canDelete,
    required this.isChecked,
    required this.projectCount,
    required this.onExport,
    required this.onRename,
    required this.onDelete,
    required this.onToggleSelection,
  });

  @override
  State<_WorkspaceRow> createState() => _WorkspaceRowState();
}

class _WorkspaceRowState extends State<_WorkspaceRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final workspace = widget.workspace;
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final accent = _softAccentColor(context.accentColor, isDark);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovering
              ? theme.dividerColor.withValues(alpha: isDark ? 0.08 : 0.04)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.compactValue(16),
          vertical: context.compactValue(12),
        ),
        child: Row(
          children: [
            // Drag handle - always visible
            ReorderableDragStartListener(
              index: widget.index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Icon(
                  Icons.drag_indicator,
                  color: _isHovering
                      ? theme.iconTheme.color?.withValues(alpha: 0.8)
                      : theme.iconTheme.color?.withValues(alpha: 0.4),
                  size: context.compactValue(18),
                ),
              ),
            ),
            SizedBox(width: context.compactValue(12)),

            // Checkbox - always visible
            Transform.scale(
              scale: 0.85,
              child: Checkbox(
                value: widget.isChecked,
                onChanged: (value) => widget.onToggleSelection(),
                activeColor: accent,
              ),
            ),
            SizedBox(width: context.compactValue(12)),

            // Icon with gradient background
            Container(
              width: context.compactValue(40),
              height: context.compactValue(40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.compactValue(8)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.2),
                    accent.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                WorkspaceIcons.getIcon(workspace.iconIndex),
                color: accent,
                size: context.compactValue(20),
              ),
            ),
            SizedBox(width: context.compactValue(16)),

            // Workspace name and badges
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      workspace.name,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: context.compactValue(15),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: context.compactValue(8)),
                  // Project count badge with tooltip
                  Tooltip(
                    message: '${widget.projectCount} project${widget.projectCount != 1 ? 's' : ''}',
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.compactValue(6),
                        vertical: context.compactValue(2),
                      ),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(
                          context.compactValue(6),
                        ),
                      ),
                      child: Text(
                        '${widget.projectCount}',
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: context.compactValue(11),
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodySmall!.color!.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  // Active workspace badge
                  if (widget.isActive) ...[
                    SizedBox(width: context.compactValue(6)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.compactValue(8),
                        vertical: context.compactValue(3),
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          context.compactValue(6),
                        ),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Active',
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: context.compactValue(10),
                          fontWeight: FontWeight.w600,
                          color: accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.compactValue(12)),

            // Action buttons - appear on hover
            AnimatedOpacity(
              opacity: _isHovering ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    onPressed: () => widget.onRename(workspace),
                    color: theme.iconTheme.color!,
                    hoverColor: accent,
                  ),
                  _ActionButton(
                    icon: Icons.download,
                    onPressed: () => widget.onExport(workspace),
                    color: theme.iconTheme.color!,
                    hoverColor: accent,
                  ),
                  if (widget.canDelete)
                    _ActionButton(
                      icon: Icons.delete_outline,
                      onPressed: () => widget.onDelete(workspace),
                      color: theme.iconTheme.color!,
                      hoverColor: theme.colorScheme.error,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color hoverColor;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.hoverColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isError = widget.hoverColor == Theme.of(context).colorScheme.error;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: context.compactValue(2)),
        decoration: BoxDecoration(
          color: _isHovered
              ? (isError
                  ? widget.hoverColor.withValues(alpha: 0.1)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05)))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(context.compactValue(8)),
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          icon: Icon(
            widget.icon,
            size: context.compactValue(18),
            color: _isHovered ? widget.hoverColor : widget.color.withValues(alpha: 0.6),
          ),
          constraints: BoxConstraints(
            minWidth: context.compactValue(36),
            minHeight: context.compactValue(36),
          ),
          padding: EdgeInsets.all(context.compactValue(8)),
          splashRadius: context.compactValue(20),
        ),
      ),
    );
  }
}

Color _softAccentColor(Color color, bool isDarkMode) {
  if (!isDarkMode) return color;
  return Color.lerp(color, Colors.white, 0.3)!;
}

class _BatchDeleteConfirmDialog extends StatelessWidget {
  final int count;

  const _BatchDeleteConfirmDialog({required this.count});

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

    return AlertDialog(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
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
      title: Text(
        'Delete $count workspace${count > 1 ? 's' : ''}?',
        style: theme.textTheme.titleLarge,
      ),
      content: Text(
        'This action cannot be undone. Projects in these workspaces will be moved to another workspace.',
        style: theme.textTheme.bodySmall!.copyWith(
          color: theme.textTheme.bodySmall!.color!.withValues(alpha: 0.8),
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
              borderRadius: BorderRadius.circular(context.compactValue(8)),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
