import '../../core/services/storage/workspace_storage_service.dart';
import '../models/workspace.dart';

class WorkspaceRepository {
  final WorkspaceStorageService _storage;

  WorkspaceRepository(this._storage);

  Future<List<Workspace>> loadWorkspaces() async {
    final data = await _storage.loadWorkspaces();
    return data.map((json) => Workspace.fromJson(json)).toList();
  }

  Future<void> saveWorkspaces(List<Workspace> workspaces) async {
    final data = workspaces.map((w) => w.toJson()).toList();
    await _storage.saveWorkspaces(data);
  }

  Future<void> addWorkspace(Workspace workspace) async {
    final workspaces = await loadWorkspaces();
    workspaces.add(workspace);
    await saveWorkspaces(workspaces);
  }

  Future<void> updateWorkspace(Workspace workspace) async {
    final workspaces = await loadWorkspaces();
    final index = workspaces.indexWhere((w) => w.id == workspace.id);
    if (index != -1) {
      workspaces[index] = workspace;
      await saveWorkspaces(workspaces);
    }
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    final workspaces = await loadWorkspaces();
    workspaces.removeWhere((w) => w.id == workspaceId);
    await saveWorkspaces(workspaces);
  }
}
