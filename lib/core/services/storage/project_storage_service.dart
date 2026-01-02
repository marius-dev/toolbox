import 'base_storage_service.dart';

/// Storage service responsible for persisting and retrieving projects.
///
/// This service follows the Single Responsibility Principle by handling
/// only project-related storage operations.
class ProjectStorageService extends BaseStorageService {
  /// Loads all projects from storage.
  ///
  /// Returns an empty list if no projects are saved or if there's an error.
  Future<List<Map<String, dynamic>>> loadProjects() async {
    final file = await projectsFile;
    return await readJsonList(file);
  }

  /// Saves the given projects to storage.
  ///
  /// Overwrites any existing projects.
  Future<void> saveProjects(List<Map<String, dynamic>> projects) async {
    final file = await projectsFile;
    await writeJsonList(file, projects);
  }
}
