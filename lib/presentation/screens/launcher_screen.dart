import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_launcher/domain/models/project.dart';
import 'package:project_launcher/presentation/screens/preferences_screen.dart';
import 'package:project_launcher/presentation/screens/workspaces_screen.dart';
import '../../core/theme/theme_extensions.dart';

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
import '../../core/di/service_locator.dart';
import '../../core/services/window_service.dart';
import '../../core/utils/compact_layout.dart';
import 'launcher/controllers/launcher_window_controller.dart';
import 'launcher/controllers/launcher_keyboard_controller.dart';
import 'launcher/controllers/launcher_search_controller.dart';
import 'launcher/controllers/launcher_project_actions.dart';
import 'launcher/launcher_intents.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  // Providers
  late final ProjectProvider _projectProvider;
  late final ToolsProvider _toolsProvider;
  late final WorkspaceProvider _workspaceProvider;

  // Controllers
  late final LauncherWindowController _windowController;
  late final LauncherKeyboardController _keyboardController;
  late final LauncherSearchController _searchController;
  late final LauncherProjectActions _projectActions;

  // UI State
  final FocusNode _projectListFocusNode = FocusNode();
  bool _showPreferences = false;
  LauncherTab _selectedTab = LauncherTab.projects;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
    _initializeControllers();
    _initializeData();
  }

  void _initializeProviders() {
    _projectProvider = ProjectProvider.create();
    _toolsProvider = ToolsProvider.create();
    _workspaceProvider = WorkspaceProvider.create();
    _toolsProvider.loadTools();
  }

  void _initializeControllers() {
    // Window controller
    _windowController = LauncherWindowController(
      windowService: getIt<WindowService>(),
      onMetadataSync: _handleMetadataSync,
    );
    _windowController.initialize();

    // Search controller
    _searchController = LauncherSearchController(
      projectProvider: _projectProvider,
      getCurrentContext: () => context,
      isProjectsTabSelected: () => _selectedTab == LauncherTab.projects,
      isPreferencesShown: () => _showPreferences,
    );

    // Keyboard controller
    _keyboardController = LauncherKeyboardController(
      onFocusSearchWithInput: ({String? initialInput}) =>
          _searchController.focusSearchField(initialInput: initialInput),
      getCurrentContext: () => context,
      isPreferencesShown: () => _showPreferences,
      isProjectsTabSelected: () => _selectedTab == LauncherTab.projects,
      isSearchFocused: () => _searchController.searchFocusNode.hasFocus,
    );
    _keyboardController.initialize();

    // Project actions controller
    _projectActions = LauncherProjectActions(
      projectProvider: _projectProvider,
      toolsProvider: _toolsProvider,
      workspaceProvider: _workspaceProvider,
      getCurrentContext: () => context,
      onSearchFieldFocus: () => _searchController.focusSearchField(),
      dismissPopupMenus: _searchController.dismissPopupMenus,
      showMessage: _showMessage,
    );
  }

  Future<void> _initializeData() async {
    await _workspaceProvider.loadWorkspaces();
    if (!mounted) return;
    final workspaceId = _workspaceProvider.selectedWorkspaceId;
    _projectProvider.setWorkspaceId(workspaceId);
    await _projectProvider.loadProjects(fallbackWorkspaceId: workspaceId);
  }

  void _handleMetadataSync() {
    if (!mounted) return;
    unawaited(_projectProvider.syncMetadataIfNeeded());
  }

  @override
  void dispose() {
    _windowController.dispose();
    _keyboardController.dispose();
    _searchController.dispose();
    _projectListFocusNode.dispose();
    _projectProvider.dispose();
    _toolsProvider.dispose();
    _workspaceProvider.dispose();
    super.dispose();
  }

  void _togglePreferences() {
    setState(() => _showPreferences = !_showPreferences);
    if (!_showPreferences) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _searchController.focusSearchField(),
      );
    }
  }

  void _focusProjectList() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_projectListFocusNode);
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

  Future<void> _openWorkspacesScreen() async {
    _searchController.dismissPopupMenus();
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

  @override
  Widget build(BuildContext context) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final shortcuts = <ShortcutActivator, Intent>{
      SingleActivator(
        LogicalKeyboardKey.keyN,
        control: !isMac,
        meta: isMac,
      ): const AddProjectIntent(),
      SingleActivator(
        LogicalKeyboardKey.comma,
        control: !isMac,
        meta: isMac,
      ): const TogglePreferencesIntent(),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          AddProjectIntent: CallbackAction<AddProjectIntent>(
            onInvoke: (_intent) {
              if (_showPreferences || _selectedTab != LauncherTab.projects) {
                return null;
              }
              _projectActions.showAddProjectDialog();
              return null;
            },
          ),
          TogglePreferencesIntent:
              CallbackAction<TogglePreferencesIntent>(
            onInvoke: (_intent) {
              _togglePreferences();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
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
                      child: _showPreferences
                          ? PreferencesScreen(
                              onBack: _togglePreferences,
                              onRescan: _toolsProvider.refresh,
                            )
                          : _buildMainView(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
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
                    (_) => _searchController.focusSearchField(),
                  );
                }
              },
              onPreferencesPressed: _togglePreferences,
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

  List<Widget> _buildProjectsArea(BuildContext context) {
    final searchBar = AnimatedBuilder(
      animation: _projectProvider,
      builder: (context, _) {
        return LauncherSearchBar(
          controller: _searchController.searchController,
          focusNode: _searchController.searchFocusNode,
          onNavigateNext: _focusProjectList,
          onSearchFocus: _searchController.dismissPopupMenus,
          onSearchChanged: _searchController.setSearchQuery,
          onAddProject: _projectActions.showAddProjectDialog,
          onImportFromGit: _projectActions.handleImportFromGit,
        );
      },
    );

    return [
      searchBar,
      SizedBox(height: context.compactValue(5)),
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
              return EmptyState(
                onAddProject: _projectActions.showAddProjectDialog,
              );
            }

            // Get other workspaces (excluding the currently selected one)
            final otherWorkspaces = _workspaceProvider.workspaces
                .where((w) => w.id != _workspaceProvider.selectedWorkspaceId)
                .toList();

            return ProjectList(
              projects: _projectProvider.projects,
              installedTools: _toolsProvider.installed,
              defaultToolId: _toolsProvider.defaultToolId,
              otherWorkspaces: otherWorkspaces,
              searchQuery: _projectProvider.searchQuery,
              focusNode: _projectListFocusNode,
              onProjectTap: _projectActions.handleOpenProject,
              onStarToggle: _projectActions.handleToggleStar,
              onShowInFinder: (project) =>
                  _projectActions.handleShowInFinder(project.path),
              onOpenInTerminal: _projectActions.handleOpenInTerminal,
              onOpenWith: _projectActions.handleOpenWith,
              onMoveToWorkspace: (project, workspaceId) =>
                  _projectProvider.moveProjectToWorkspace(project, workspaceId),
              onDelete: _projectActions.handleDeleteProject,
              onFocusSearch: () => _searchController.focusSearchField(),
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
}
