import 'package:flutter/material.dart';
import '../../domain/models/project.dart';
import 'project_item.dart';

class ProjectList extends StatelessWidget {
  final List<Project> projects;
  final ValueChanged<Project> onProjectTap;
  final ValueChanged<Project> onStarToggle;
  final ValueChanged<Project> onShowInFinder;
  final void Function(Project project, OpenWithApp app) onOpenWith;
  final ValueChanged<Project> onDelete;

  const ProjectList({
    Key? key,
    required this.projects,
    required this.onProjectTap,
    required this.onStarToggle,
    required this.onShowInFinder,
    required this.onOpenWith,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectItem(
          project: project,
          onTap: () => onProjectTap(project),
          onStarToggle: () => onStarToggle(project),
          onShowInFinder: () => onShowInFinder(project),
          onOpenWith: (app) => onOpenWith(project, app),
          onDelete: () => onDelete(project),
        );
      },
    );
  }
}
