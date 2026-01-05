import '../../core/services/project_metadata_service.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';

/// Service responsible for keeping project metadata in sync with Git.
///
/// It fetches repository metadata using [ProjectMetadataService] and persists
/// the enriched project data via [ProjectRepository].
class ProjectMetadataSyncService {
  ProjectMetadataSyncService(this._repository, this._metadataService);

  final ProjectRepository _repository;
  final ProjectMetadataService _metadataService;

  /// Ensures every project has up-to-date Git metadata and persists the result.
  Future<List<Project>> syncMetadata(List<Project> projects) async {
    if (projects.isEmpty) return projects;

    final updated = <Project>[];

    for (final project in projects) {
      if (!project.pathExists) {
        updated.add(project.copyWith(gitInfo: const ProjectGitInfo()));
        continue;
      }

      final gitInfo = await _metadataService.fetchGitInfo(project.path);
      updated.add(project.copyWith(gitInfo: gitInfo));
    }

    await _repository.saveProjects(updated);
    return updated;
  }
}
