import '../../../domain/models/project.dart';

class ProjectSections {
  final List<Project> favorites;
  final List<Project> others;
  final List<Project> ordered;

  ProjectSections({required this.favorites, required this.others})
    : ordered = [...favorites, ...others];
}
