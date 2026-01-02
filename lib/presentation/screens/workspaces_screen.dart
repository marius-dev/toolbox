import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme_extensions.dart';

import '../../core/di/service_locator.dart';
import '../../core/services/window_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';
import '../../domain/models/project.dart';
import '../../domain/models/tool.dart';
import '../../domain/models/workspace.dart';
import '../providers/project_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/glass_action_button.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_panel.dart';
import '../widgets/launcher/project_list_scroll_behavior.dart';
import '../widgets/section_layout.dart';
import '../widgets/workspace_dialog.dart';

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
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const WorkspaceDialog(),
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await widget.workspaceProvider.createWorkspace(trimmed);
  }

  Future<void> _renameWorkspace(Workspace workspace) async {
    if (workspace.isDefault) {
      _showMessage('Default workspace cannot be renamed');
      return;
    }
    final name = await showDialog<String>(
      context: context,
      builder: (context) => WorkspaceDialog(workspace: workspace),
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await widget.workspaceProvider.renameWorkspace(workspace, trimmed);
  }

  Future<void> _deleteWorkspace(Workspace workspace) async {
    if (workspace.isDefault) {
      _showMessage('Default workspace cannot be removed');
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

  Future<void> _selectWorkspace(Workspace workspace) async {
    await widget.workspaceProvider.setSelectedWorkspace(workspace.id);
    widget.projectProvider.setWorkspaceId(workspace.id);
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

    return Focus(
      autofocus: true,
      onKey: _handleEscapeKey,
      child: AppShell(
        blurSigma: 40,
        builder: (context, _) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: _introController, curve: curve),
            child: _buildContent(context, duration, curve),
          );
        },
      ),
    );
  }

  KeyEventResult _handleEscapeKey(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildContent(BuildContext context, Duration duration, Curve curve) {
    final horizontalPadding =
        context.compactPadding(horizontal: 18);

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
            child: CircularProgressIndicator(
              color: context.accentColor,
            ),
          );
        }
        final workspaces = widget.workspaceProvider.workspaces;
        final selectedId = widget.workspaceProvider.selectedWorkspaceId;
        final theme = Theme.of(context);
        final isDark = context.isDark;
        final background = isDark
            ? Colors.black.withOpacity(0.5)
            : Colors.white.withOpacity(0.9);
        final borderColor = theme.dividerColor.withOpacity(0.16);

        return Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: ScrollConfiguration(
              behavior: const ProjectListScrollBehavior(),
              child: Scrollbar(
                controller: _scrollController,
                radius: const Radius.circular(6),
                thickness: 4,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: context.compactPadding(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: workspaces.length,
                  itemBuilder: (context, index) {
                    final workspace = workspaces[index];
                    return _WorkspaceRow(
                      workspace: workspace,
                      isSelected: workspace.id == selectedId,
                      onExport: _exportWorkspace,
                      onRename: _renameWorkspace,
                      onDelete: _deleteWorkspace,
                      onSelect: _selectWorkspace,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, Duration duration, Curve curve) {
    final isDark = context.isDark;
    final bottomColor = isDark ? Colors.black.withOpacity(0.42) : null;

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
  final bool isSelected;
  final Future<void> Function(Workspace) onExport;
  final Future<void> Function(Workspace) onRename;
  final Future<void> Function(Workspace) onDelete;
  final Future<void> Function(Workspace) onSelect;

  const _WorkspaceRow({
    required this.workspace,
    required this.isSelected,
    required this.onExport,
    required this.onRename,
    required this.onDelete,
    required this.onSelect,
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
    final background = widget.isSelected
        ? accent.withOpacity(isDark ? 0.24 : 0.12)
        : _isHovering
        ? theme.dividerColor.withOpacity(isDark ? 0.12 : 0.08)
        : Colors.transparent;
    final borderColor = widget.isSelected
        ? accent.withOpacity(0.85)
        : Colors.transparent;
    final muted = theme.textTheme.bodySmall!.color!.withOpacity(0.7);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelect(workspace),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(bottom: context.compactValue(6)),
          padding: EdgeInsets.symmetric(
            horizontal: context.compactValue(12),
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.2 : 1,
            ),
          ),
          child: SizedBox(
            height: context.compactValue(56),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.compactValue(8)),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(
                      context.compactValue(10),
                    ),
                  ),
                  child: Icon(
                    Icons.layers_rounded,
                    size: context.compactValue(18),
                    color: theme.iconTheme.color,
                  ),
                ),
                SizedBox(width: context.compactValue(12)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workspace.name,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: context.compactValue(4)),
                      Text(
                        'Workspace',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!workspace.isDefault)
                      GlassButton(
                        icon: Icons.edit_rounded,
                        tooltip: 'Rename workspace',
                        tintColor: theme.colorScheme.primary,
                        onPressed: () {
                          widget.onRename(workspace);
                        },
                      ),
                    if (!workspace.isDefault)
                      SizedBox(width: context.compactValue(8)),
                    GlassButton(
                      icon: Icons.download_rounded,
                      tooltip: 'Export workspace',
                      tintColor: context.accentColor,
                      onPressed: () {
                        widget.onExport(workspace);
                      },
                    ),
                    if (!workspace.isDefault)
                      SizedBox(width: context.compactValue(8)),
                    if (!workspace.isDefault)
                      GlassButton(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Remove workspace',
                        tintColor: theme.colorScheme.error,
                        onPressed: () {
                          widget.onDelete(workspace);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _softAccentColor(Color color, bool isDarkMode) {
  if (!isDarkMode) return color;
  return Color.lerp(color, Colors.white, 0.3)!;
}
