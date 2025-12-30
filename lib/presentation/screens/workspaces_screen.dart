import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';
import '../../domain/models/workspace.dart';
import '../providers/project_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_panel.dart';
import '../widgets/launcher/project_list_scroll_behavior.dart';
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
  late final AnimationController _introController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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

  void _showMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final palette = GlassStylePalette.fromContext(
      context,
      style: ThemeProvider.instance.glassStyle,
      accentColor: ThemeProvider.instance.accentColor,
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
                    child: _buildContent(context, duration, curve),
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
                  child: Padding(
                    padding: CompactLayout.symmetric(context, horizontal: 18),
                    child: _buildWorkspaceList(context),
                  ),
                ),
                SizedBox(height: CompactLayout.value(context, 12)),
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
                'Manage workspaces',
                style: textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: CompactLayout.value(context, 4)),
              Text(
                'Create, rename, and organize your workspaces.',
                style: textTheme.bodyMedium!.copyWith(color: muted),
              ),
            ],
          ),
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
              color: ThemeProvider.instance.accentColor,
            ),
          );
        }
        final workspaces = widget.workspaceProvider.workspaces;
        final selectedId = widget.workspaceProvider.selectedWorkspaceId;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
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
                  padding: CompactLayout.symmetric(
                    context,
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: workspaces.length,
                  itemBuilder: (context, index) {
                    final workspace = workspaces[index];
                    return _WorkspaceRow(
                      workspace: workspace,
                      isSelected: workspace.id == selectedId,
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

  Widget _buildBottomBar(
    BuildContext context,
    Duration duration,
    Curve curve,
  ) {
    return GlassPanel(
      duration: duration,
      curve: curve,
      padding: EdgeInsets.symmetric(
        horizontal: CompactLayout.value(context, 18),
        vertical: CompactLayout.value(context, 14),
      ),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(0),
      ),
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [_buildCreateButton(context)],
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    final accentColor = ThemeProvider.instance.accentColor;

    return ElevatedButton.icon(
      onPressed: _createWorkspace,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add workspace'),
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: CompactLayout.value(context, 18),
          vertical: CompactLayout.value(context, 12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CompactLayout.value(context, 12)),
        ),
      ),
    );
  }
}

class _WorkspaceRow extends StatefulWidget {
  final Workspace workspace;
  final bool isSelected;
  final Future<void> Function(Workspace) onRename;
  final Future<void> Function(Workspace) onDelete;
  final Future<void> Function(Workspace) onSelect;

  const _WorkspaceRow({
    required this.workspace,
    required this.isSelected,
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
    final isDark = theme.brightness == Brightness.dark;
    final accent =
        _softAccentColor(ThemeProvider.instance.accentColor, isDark);
    final background = widget.isSelected
        ? accent.withOpacity(isDark ? 0.24 : 0.12)
        : _isHovering
        ? theme.dividerColor.withOpacity(isDark ? 0.12 : 0.08)
        : Colors.transparent;
    final borderColor =
        widget.isSelected ? accent.withOpacity(0.85) : Colors.transparent;
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
          margin: EdgeInsets.only(bottom: CompactLayout.value(context, 6)),
          padding: EdgeInsets.symmetric(
            horizontal: CompactLayout.value(context, 12),
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
            height: CompactLayout.value(context, 56),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(CompactLayout.value(context, 8)),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(
                      CompactLayout.value(context, 10),
                    ),
                  ),
                  child: Icon(
                    Icons.layers_rounded,
                    size: CompactLayout.value(context, 18),
                    color: theme.iconTheme.color,
                  ),
                ),
                SizedBox(width: CompactLayout.value(context, 12)),
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
                      SizedBox(height: CompactLayout.value(context, 4)),
                      Text(
                        'Workspace',
                        style: theme.textTheme.bodySmall!.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                if (!workspace.isDefault)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassButton(
                        icon: Icons.edit_rounded,
                        tooltip: 'Rename workspace',
                        tintColor: theme.colorScheme.primary,
                        onPressed: () {
                          widget.onRename(workspace);
                        },
                      ),
                      SizedBox(width: CompactLayout.value(context, 8)),
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
