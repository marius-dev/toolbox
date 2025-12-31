import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_launcher/domain/models/project.dart';
import 'package:project_launcher/presentation/screens/add_project_screen.dart';
import 'package:project_launcher/presentation/screens/settings_screen.dart';
import 'package:project_launcher/presentation/screens/workspaces_screen.dart';
import 'package:project_launcher/presentation/widgets/project_dialog.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/project_provider.dart';
import '../providers/tools_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/empty_state.dart';
import '../widgets/launcher/launcher_header.dart';
import '../widgets/launcher/launcher_search_bar.dart';
import '../widgets/launcher/launcher_tab_bar.dart';
import '../widgets/launcher/project_list.dart';
import '../widgets/tools_section.dart';
import '../../core/services/window_service.dart';
import '../../core/utils/compact_layout.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> with WindowListener {
  late final ProjectProvider _projectProvider;
  late final ToolsProvider _toolsProvider;
  late final WorkspaceProvider _workspaceProvider;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _projectListFocusNode = FocusNode();
  bool _showSettings = false;
  LauncherTab _selectedTab = LauncherTab.projects;
  bool _wasHidden = false;

  @override
  void initState() {
    super.initState();
    _projectProvider = ProjectProvider.create();
    _toolsProvider = ToolsProvider.create();
    _workspaceProvider = WorkspaceProvider.create();
    _initializeData();
    _toolsProvider.loadTools();
    windowManager.addListener(this);
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _projectListFocusNode.dispose();
    _projectProvider.dispose();
    _toolsProvider.dispose();
    _workspaceProvider.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _workspaceProvider.loadWorkspaces();
    if (!mounted) return;
    final workspaceId = _workspaceProvider.selectedWorkspaceId;
    _projectProvider.setWorkspaceId(workspaceId);
    await _projectProvider.loadProjects(fallbackWorkspaceId: workspaceId);
  }

  @override
  void onWindowBlur() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!WindowService.instance.shouldAutoHideOnBlur) return;
      _wasHidden = true;
      WindowService.instance.hide();
    });
  }

  @override
  void onWindowFocus() {
    _handleWindowVisible();
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'hide') {
      _wasHidden = true;
      return;
    }
    if (eventName == 'show') {
      _handleWindowVisible();
    }
  }

  void _handleWindowVisible() {
    if (!_wasHidden) return;
    _wasHidden = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_projectProvider.syncMetadataIfNeeded());
    });
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
    if (!_showSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusSearchField());
    }
  }

  void _focusSearchField({String? initialInput}) {
    if (!mounted || _selectedTab != LauncherTab.projects || _showSettings)
      return;
    _dismissPopupMenus();
    if (initialInput != null && initialInput.isNotEmpty) {
      _insertInitialSearchInput(initialInput);
    }
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  void _focusProjectList() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_projectListFocusNode);
  }

  void _dismissPopupMenus() {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route is! PopupRoute);
  }

  void _insertInitialSearchInput(String input) {
    final text = _searchController.text;
    final selection = _searchController.selection;
    final hasSelection =
        selection.isValid &&
        selection.start >= 0 &&
        selection.end <= text.length;
    final start = hasSelection ? selection.start : text.length;
    final end = hasSelection ? selection.end : text.length;
    final newText = text.replaceRange(start, end, input);
    final newSelection = TextSelection.collapsed(offset: start + input.length);

    _searchController.value = TextEditingValue(
      text: newText,
      selection: newSelection,
    );
    _projectProvider.setSearchQuery(newText);
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    if (event is! RawKeyDownEvent) return;
    if (_showSettings || _selectedTab != LauncherTab.projects) return;
    final hasModifiers =
        event.isControlPressed || event.isMetaPressed || event.isAltPressed;
    if (_searchFocusNode.hasFocus) return;
    if (hasModifiers) {
      return;
    }

    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    if (focusedWidget is EditableText) return;

    final character = event.character;
    final isAlphanumeric =
        character != null && RegExp(r'^[a-zA-Z0-9]$').hasMatch(character);
    if (!isAlphanumeric) return;

    _focusSearchField(initialInput: character);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: () => FocusScope.of(context).unfocus(),
      child: AppShell(
        blurSigma: 40,
        glows: const [
          GlowSpec(
            alignment: Alignment.topRight,
            offset: Offset(20, -120),
            size: 280,
            angle: 0.5,
            thickness: 0.34,
          ),
          GlowSpec(
            alignment: Alignment.bottomLeft,
            offset: Offset(-30, 140),
            size: 360,
            opacity: 0.84,
            angle: -0.28,
            thickness: 0.46,
          ),
        ],
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: _showSettings
                    ? SettingsScreen(
                        onBack: _toggleSettings,
                        onRescan: _toolsProvider.refresh,
                      )
                    : _buildMainView(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainView() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _projectProvider,
        _toolsProvider,
        _workspaceProvider,
      ]),
      builder: (context, _) {
        final hasMissingPaths = _projectProvider.projects.any(
          (project) => !project.pathExists,
        );

        return Column(
          children: [
            LauncherHeader(
              selectedTab: _selectedTab,
              onTabSelected: (tab) {
                setState(() => _selectedTab = tab);
                if (_selectedTab == LauncherTab.tools) {
                  _toolsProvider.loadTools();
                } else {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _focusSearchField(),
                  );
                }
              },
              onSettingsPressed: _toggleSettings,
              hasSyncErrors: hasMissingPaths,
              isSyncing: _projectProvider.isSyncing,
              onSyncMetadata: _projectProvider.syncMetadata,
              workspaces: _workspaceProvider.workspaces,
              selectedWorkspace: _workspaceProvider.selectedWorkspace,
              isWorkspaceLoading: _workspaceProvider.isLoading,
              onWorkspaceSelected: (workspaceId) async {
                await _workspaceProvider.setSelectedWorkspace(workspaceId);
                _projectProvider.setWorkspaceId(workspaceId);
              },
              onManageWorkspaces: _openWorkspacesScreen,
            ),
            if (_selectedTab == LauncherTab.projects)
              ..._buildProjectsArea(context)
            else
              _buildToolsArea(),
          ],
        );
      },
    );
  }

  Future<void> _openAddProjectScreen() async {
    _dismissPopupMenus();
    final workspaceId = _workspaceProvider.selectedWorkspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      _showMessage('Workspace not ready');
      return;
    }
    final created = await Navigator.of(
      context,
    ).push<bool>(_buildAddProjectRoute(workspaceId));
    if (!mounted) return;
    if (created == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusSearchField());
    }
  }

  PageRouteBuilder<bool> _buildAddProjectRoute(String workspaceId) {
    return PageRouteBuilder<bool>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        final child = AddProjectScreen(
          projectProvider: _projectProvider,
          toolsProvider: _toolsProvider,
          workspaceId: workspaceId,
        );
        final media = MediaQuery.of(context);
        if (media.disableAnimations || media.accessibleNavigation) {
          return child;
        }

        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _handleImportFromGit() {
    _showUnavailableAction('Import from Git');
  }

  Future<void> _openWorkspacesScreen() async {
    _dismissPopupMenus();
    await Navigator.of(context).push<bool>(_buildWorkspacesRoute());
  }

  PageRouteBuilder<bool> _buildWorkspacesRoute() {
    return PageRouteBuilder<bool>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        final child = WorkspacesScreen(
          workspaceProvider: _workspaceProvider,
          projectProvider: _projectProvider,
        );
        final media = MediaQuery.of(context);
        if (media.disableAnimations || media.accessibleNavigation) {
          return child;
        }

        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showUnavailableAction(String label) {
    _showMessage('$label is not available yet');
  }

  void _showMessage(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  void _showEditProjectDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectDialog(
        project: project,
        defaultToolId: _toolsProvider.defaultToolId,
        onSave: (name, path, _) {
          _projectProvider.updateProject(
            project.copyWith(name: name, path: path),
          );
        },
      ),
    );
  }

  List<Widget> _buildProjectsArea(BuildContext context) {
    final searchBar = AnimatedBuilder(
      animation: _projectProvider,
      builder: (context, _) {
        return LauncherSearchBar(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onNavigateNext: _focusProjectList,
          onSearchFocus: _dismissPopupMenus,
          onSearchChanged: _projectProvider.setSearchQuery,
          onAddProject: _openAddProjectScreen,
          onImportFromGit: _handleImportFromGit,
        );
      },
    );

    return [
      searchBar,
      SizedBox(height: CompactLayout.value(context, 5)),
      Expanded(
        child: AnimatedBuilder(
          animation: Listenable.merge([_projectProvider, _toolsProvider]),
          builder: (context, _) {
            if (_workspaceProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_projectProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!_projectProvider.hasProjects) {
              return EmptyState(onAddProject: _openAddProjectScreen);
            }

            return ProjectList(
              projects: _projectProvider.projects,
              installedTools: _toolsProvider.installed,
              defaultToolId: _toolsProvider.defaultToolId,
              searchQuery: _projectProvider.searchQuery,
              focusNode: _projectListFocusNode,
              onProjectTap: _handleProjectOpen,
              onStarToggle: _projectProvider.toggleStar,
              onShowInFinder: (project) =>
                  _projectProvider.showInFinder(project.path),
              onOpenInTerminal: (project) =>
                  _projectProvider.openInTerminal(project),
              onOpenWith: (project, toolId) => _projectProvider.openWith(
                project,
                toolId,
                defaultToolId: _toolsProvider.defaultToolId,
                installedTools: _toolsProvider.installed,
              ),
              onDelete: (project) => _projectProvider.deleteProject(project.id),
              onFocusSearch: _focusSearchField,
            );
          },
        ),
      ),
    ];
  }

  Widget _buildToolsArea() {
    return Expanded(
      child: AnimatedBuilder(
        animation: _toolsProvider,
        builder: (context, _) {
          return ToolsSection(
            installed: _toolsProvider.installed,
            isLoading: _toolsProvider.isLoading,
            defaultToolId: _toolsProvider.defaultToolId,
            onDefaultChanged: (id) => _toolsProvider.setDefaultTool(id),
            onLaunch: (tool) => _toolsProvider.launch(tool),
          );
        },
      ),
    );
  }

  Future<void> _handleProjectOpen(Project project) async {
    await _projectProvider.openProject(
      project,
      defaultToolId: _toolsProvider.defaultToolId,
      installedTools: _toolsProvider.installed,
      refreshDelay: const Duration(seconds: 1),
    );
  }
}
