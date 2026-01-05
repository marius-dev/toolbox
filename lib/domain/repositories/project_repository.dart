import '../../core/services/storage/project_storage_service.dart';
import '../models/project.dart';

class ProjectRepository {
  final ProjectStorageService _storage;

  ProjectRepository(this._storage);

  Future<List<Project>> loadProjects() async {
    final data = await _storage.loadProjects();
    return data.map((json) => Project.fromJson(json)).toList();
  }

  Future<void> saveProjects(List<Project> projects) async {
    final data = projects.map((p) => p.toJson()).toList();
    await _storage.saveProjects(data);
  }

  Future<void> addProject(Project project) async {
    final projects = await loadProjects();
    projects.add(project);
    await saveProjects(projects);
  }

  Future<void> addProjects(List<Project> projects) async {
    if (projects.isEmpty) return;
    final existing = await loadProjects();
    existing.addAll(projects);
    await saveProjects(existing);
  }

  Future<void> updateProject(Project project) async {
    final projects = await loadProjects();
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      await saveProjects(projects);
    }
  }

  Future<void> deleteProject(String projectId) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p.id == projectId);
    await saveProjects(projects);
  }
}
