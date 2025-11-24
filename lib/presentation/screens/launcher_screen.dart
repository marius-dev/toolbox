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
  const LauncherScreen({Key? key}) : super(key: key);

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> with WindowListener {
  late final ProjectProvider _projectProvider;
  late final ToolsProvider _toolsProvider;
  final TextEditingController _searchController = TextEditingController();
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
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _searchController.dispose();
    _projectProvider.dispose();
    _toolsProvider.dispose();
    super.dispose();
  }

  @override
  void onWindowBlur() {
    Future.delayed(const Duration(milliseconds: 100), () {
      WindowService.instance.hide();
    });
  }

  void _toggleSettings() {
    setState(() => _showSettings = !_showSettings);
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
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
            Color.lerp(accentColor, Colors.black, 0.7)!,
            const Color(0xFF0E1118),
            const Color(0xFF0B0D14),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: _showSettings
          ? SettingsScreen(onBack: _toggleSettings)
          : _buildMainView(),
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

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProjectDialog(
        onSave: (name, path, type) {
          _projectProvider.addProject(name: name, path: path, type: type);
        },
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectDialog(
        project: project,
        onSave: (name, path, type) {
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
              onDelete: (project) =>
                  _projectProvider.deleteProject(project.id),
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
            onRefresh: () => _toolsProvider.refresh(),
            defaultToolId: _toolsProvider.defaultToolId,
            onDefaultChanged: (id) => _toolsProvider.setDefaultTool(id),
            onLaunch: (tool) => _toolsProvider.launch(tool),
          );
        },
      ),
    );
  }
}
