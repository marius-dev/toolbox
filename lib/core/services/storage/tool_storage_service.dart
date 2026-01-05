import 'base_storage_service.dart';
import 'storage_keys.dart';

/// Storage service responsible for tool preferences.
///
/// This service follows the Single Responsibility Principle by handling
/// only tool-related preferences such as the default tool selection.
class ToolStorageService extends BaseStorageService {
  /// Gets the default tool ID from preferences.
  ///
  /// Returns null if no default tool has been set.
  Future<String?> getDefaultToolId() async {
    final prefs = await readPreferences();
    final id = prefs[StorageKeys.defaultToolId];
    if (id is String && id.isNotEmpty) {
      return id;
    }
    return null;
  }

  /// Saves the default tool ID to preferences.
  ///
  /// Pass null to clear the default tool selection.
  Future<void> saveDefaultToolId(String? toolId) async {
    final prefs = await readPreferences();
    if (toolId == null) {
      prefs.remove(StorageKeys.defaultToolId);
    } else {
      prefs[StorageKeys.defaultToolId] = toolId;
    }
    await writePreferences(prefs);
  }
}
