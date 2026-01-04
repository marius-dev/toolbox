import '../models/workspace.dart';
import '../repositories/workspace_repository.dart';

class WorkspaceUseCases {
  final WorkspaceRepository _repository;

  WorkspaceUseCases(this._repository);

  Future<List<Workspace>> getAllWorkspaces() => _repository.loadWorkspaces();

  Future<Workspace> addWorkspace({
    required String name,
    bool isDefault = false,
    int? iconIndex,
  }) async {
    final workspace = Workspace.create(
      name: name,
      isDefault: isDefault,
      iconIndex: iconIndex,
    );
    await _repository.addWorkspace(workspace);
    return workspace;
  }

  Future<void> updateWorkspace(Workspace workspace) async {
    await _repository.updateWorkspace(workspace);
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    await _repository.deleteWorkspace(workspaceId);
  }
}
