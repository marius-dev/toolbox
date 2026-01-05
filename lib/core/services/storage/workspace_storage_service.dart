import 'base_storage_service.dart';
import 'storage_keys.dart';

/// Storage service responsible for persisting and retrieving workspaces.
///
/// This service follows the Single Responsibility Principle by handling
/// workspace-related storage operations including workspace selection.
class WorkspaceStorageService extends BaseStorageService {
  /// Loads all workspaces from storage.
  ///
  /// Returns an empty list if no workspaces are saved or if there's an error.
  Future<List<Map<String, dynamic>>> loadWorkspaces() async {
    final file = await workspacesFile;
    return await readJsonList(file);
  }

  /// Saves the given workspaces to storage.
  ///
  /// Overwrites any existing workspaces.
  Future<void> saveWorkspaces(List<Map<String, dynamic>> workspaces) async {
    final file = await workspacesFile;
    await writeJsonList(file, workspaces);
  }

  /// Gets the currently selected workspace ID from preferences.
  ///
  /// Returns null if no workspace is selected.
  Future<String?> getSelectedWorkspaceId() async {
    final prefs = await readPreferences();
    final id = prefs[StorageKeys.selectedWorkspaceId];
    if (id is String && id.isNotEmpty) {
      return id;
    }
    return null;
  }

  /// Saves the selected workspace ID to preferences.
  ///
  /// Pass null or empty string to clear the selection.
  Future<void> saveSelectedWorkspaceId(String? workspaceId) async {
    final prefs = await readPreferences();
    if (workspaceId == null || workspaceId.isEmpty) {
      prefs.remove(StorageKeys.selectedWorkspaceId);
    } else {
      prefs[StorageKeys.selectedWorkspaceId] = workspaceId;
    }
    await writePreferences(prefs);
  }
}
