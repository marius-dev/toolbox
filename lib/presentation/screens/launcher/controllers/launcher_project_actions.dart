import 'package:flutter/material.dart';

import '../../../../domain/models/project.dart';
import '../../../../domain/models/tool.dart';
import '../../../providers/project_provider.dart';
import '../../../providers/tools_provider.dart';
import '../../../providers/workspace_provider.dart';
import '../../../widgets/project_dialog.dart';
import '../../../utils/dialog_utils.dart';

/// Controller responsible for project-related operations in the launcher.
///
/// Handles:
/// - Adding new projects
/// - Editing existing projects
/// - Deleting projects
/// - Opening projects with various tools
/// - Project dialog management
/// - Import operations
class LauncherProjectActions {
  LauncherProjectActions({
    required ProjectProvider projectProvider,
    required ToolsProvider toolsProvider,
    required WorkspaceProvider workspaceProvider,
    required this.getCurrentContext,
    required this.onSearchFieldFocus,
    required this.dismissPopupMenus,
    required this.showMessage,
  })  : _projectProvider = projectProvider,
        _toolsProvider = toolsProvider,
        _workspaceProvider = workspaceProvider;

  final ProjectProvider _projectProvider;
  final ToolsProvider _toolsProvider;
  final WorkspaceProvider _workspaceProvider;
  final BuildContext Function() getCurrentContext;
  final VoidCallback onSearchFieldFocus;
  final VoidCallback dismissPopupMenus;
  final void Function(String message, {Duration duration}) showMessage;

  /// Show the dialog to add a new project
  Future<void> showAddProjectDialog() async {
    dismissPopupMenus();

    final workspaceId = _workspaceProvider.selectedWorkspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      showMessage('Workspace not ready');
      return;
    }

    final context = getCurrentContext();
    final created = await DialogUtils.showAppDialog<bool>(
      context: context,
      builder: (context) => ProjectDialog(
        defaultToolId: _toolsProvider.defaultToolId,
        onSave: (name, path, preferredToolId) async {
          await _projectProvider.addProject(
            name: name,
            path: path,
            preferredToolId: preferredToolId,
            workspaceId: workspaceId,
          );
        },
      ),
    );

    if (created == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onSearchFieldFocus());
    }
  }

  /// Show the dialog to edit an existing project
  void showEditProjectDialog(Project project) {
    final context = getCurrentContext();
    DialogUtils.showAppDialog(
      context: context,
      builder: (context) => ProjectDialog(
        project: project,
        defaultToolId: _toolsProvider.defaultToolId,
        onSave: (name, path, _) async {
          await _projectProvider.updateProject(
            project.copyWith(name: name, path: path),
          );
        },
      ),
    );
  }

  /// Handle opening a project with its preferred or default tool
  Future<void> handleOpenProject(Project project) async {
    await _projectProvider.openProject(
      project,
      defaultToolId: _toolsProvider.defaultToolId,
      installedTools: _toolsProvider.installed,
      refreshDelay: const Duration(seconds: 1),
    );
  }

  /// Handle deleting a project
  Future<void> handleDeleteProject(Project project) async {
    await _projectProvider.deleteProject(project.id);
  }

  /// Handle toggling the star status of a project
  Future<void> handleToggleStar(Project project) async {
    await _projectProvider.toggleStar(project);
  }

  /// Handle showing a project in Finder
  Future<void> handleShowInFinder(String path) async {
    await _projectProvider.showInFinder(path);
  }

  /// Handle opening a project in Terminal
  void handleOpenInTerminal(Project project) {
    _projectProvider.openInTerminal(project);
  }

  /// Handle opening a project with a specific tool
  void handleOpenWith(Project project, ToolId toolId) {
    _projectProvider.openWith(
      project,
      toolId,
      defaultToolId: _toolsProvider.defaultToolId,
      installedTools: _toolsProvider.installed,
    );
  }

  /// Handle the import from Git action (placeholder)
  void handleImportFromGit() {
    _showUnavailableAction('Import from Git');
  }

  void _showUnavailableAction(String label) {
    showMessage('$label is not available yet');
  }
}
