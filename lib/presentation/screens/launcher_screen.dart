import 'package:flutter/material.dart';
import 'package:project_launcher/domain/models/project.dart';
import 'package:project_launcher/presentation/screens/settings_screen.dart';
import 'package:project_launcher/presentation/widgets/project_dialog.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';
import '../providers/project_provider.dart';
import '../widgets/launcher_header.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/search_sort_bar.dart';
import '../widgets/project_list.dart';
import '../widgets/empty_state.dart';
import '../providers/tools_provider.dart';
import '../widgets/tools_section.dart';
import '../../core/services/window_service.dart';
import '../../core/theme/theme_provider.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> with WindowListener {
  late final ProjectProvider _projectProvider;
  late final ToolsProvider _toolsProvider;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _projectListFocusNode = FocusNode();
  bool _showSettings = false;
  LauncherTab _selectedTab = LauncherTab.projects;

  @override
  void initState() {
    super.initState();
    _projectProvider = ProjectProvider.create();
    _toolsProvider = ToolsProvider.create();
    _projectProvider.loadProjects();
    _toolsProvider.loadTools();
    windowManager.addListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusSearchField());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _projectListFocusNode.dispose();
    _projectProvider.dispose();
    _toolsProvider.dispose();
    super.dispose();
  }

  @override
  void onWindowBlur() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!WindowService.instance.shouldAutoHideOnBlur) return;
      WindowService.instance.hide();
    });
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
    if (!_showSettings) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusSearchField());
    }
  }

  void _focusSearchField() {
    if (!mounted || _selectedTab != LauncherTab.projects || _showSettings)
      return;
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  void _focusProjectList() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_projectListFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: () => FocusScope.of(context).unfocus(),
        child: _buildContainer(),
      ),
    );
  }

  Widget _buildContainer() {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final isDark = ThemeProvider.instance.isDarkMode;
        final accentColor = ThemeProvider.instance.accentColor;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF05070F),
                      Color.alphaBlend(
                        accentColor.withOpacity(0.12),
                        const Color(0xFF05070F),
                      ),
                      const Color(0xFF090F1F),
                    ]
                  : [
                      Colors.white,
                      Colors.white,
                      Colors.white.withOpacity(0.95),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.65)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
              if (isDark)
                BoxShadow(
                  color: accentColor.withOpacity(0.25),
                  blurRadius: 90,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: _buildContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    final isDark = ThemeProvider.instance.isDarkMode;
    final accentColor = ThemeProvider.instance.accentColor;

    final backgroundGradient = isDark
        ? [
            const Color(0xFF070C18),
            Color.alphaBlend(
              accentColor.withOpacity(0.18),
              const Color(0xFF070C18),
            ),
            const Color(0xFF0F1428),
          ]
        : [
            _lighten(accentColor, 0.4),
            _lighten(accentColor, 0.7),
            Colors.white,
          ];

    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundGradient,
        ),
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -20,
            child: _buildGlow(accentColor, 240),
          ),
          Positioned(
            bottom: -140,
            left: -30,
            child: _buildGlow(accentColor.withOpacity(0.8), 320),
          ),
          Positioned.fill(
            child: _showSettings
                ? SettingsScreen(
                    onBack: _toggleSettings,
                    onRescan: _toolsProvider.refresh,
                  )
                : _buildMainView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return Column(
      children: [
        LauncherHeader(
          onSettingsPressed: _toggleSettings,
          onAddProject: () => _showAddProjectDialog(context),
        ),
        TabBarWidget(
          selectedTab: _selectedTab,
          toolsBadge: _toolsProvider.installedCount,
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
        ),
        if (_selectedTab == LauncherTab.projects)
          ..._buildProjectsArea(context)
        else
          _buildToolsArea(),
      ],
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Widget _buildGlow(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.22), Colors.transparent],
          ),
        ),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProjectDialog(
        defaultToolId: _toolsProvider.defaultToolId,
        onSave: (name, path, type, preferredToolId) {
          _projectProvider.addProject(
            name: name,
            path: path,
            type: type,
            preferredToolId: preferredToolId,
          );
        },
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectDialog(
        project: project,
        defaultToolId: _toolsProvider.defaultToolId,
        onSave: (name, path, type, _) {
          _projectProvider.updateProject(
            project.copyWith(name: name, path: path, type: type),
          );
        },
      ),
    );
  }

  List<Widget> _buildProjectsArea(BuildContext context) {
    return [
      SearchSortBar(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onNavigateNext: _focusProjectList,
        onSearchChanged: _projectProvider.setSearchQuery,
        currentSort: _projectProvider.sortOption,
        onSortChanged: _projectProvider.setSortOption,
      ),
      Expanded(
        child: AnimatedBuilder(
          animation: Listenable.merge([_projectProvider, _toolsProvider]),
          builder: (context, _) {
            if (_projectProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!_projectProvider.hasProjects) {
              return EmptyState(
                onAddProject: () => _showAddProjectDialog(context),
              );
            }

            return ProjectList(
              projects: _projectProvider.projects,
              installedTools: _toolsProvider.installed,
              defaultToolId: _toolsProvider.defaultToolId,
              focusNode: _projectListFocusNode,
              onProjectTap: (project) => _projectProvider.openProject(
                project,
                defaultToolId: _toolsProvider.defaultToolId,
                installedTools: _toolsProvider.installed,
              ),
              onStarToggle: _projectProvider.toggleStar,
              onShowInFinder: (project) =>
                  _projectProvider.showInFinder(project.path),
              onOpenWith: (project, app) => _projectProvider.openWith(
                project,
                app,
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
            available: _toolsProvider.available,
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
