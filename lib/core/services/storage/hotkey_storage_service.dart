import 'base_storage_service.dart';
import 'storage_keys.dart';

/// Storage service responsible for hotkey preferences.
///
/// This service follows the Single Responsibility Principle by handling
/// only hotkey-related storage operations.
class HotkeyStorageService extends BaseStorageService {
  /// Gets the saved hotkey preference from storage.
  ///
  /// Returns null if no hotkey has been configured.
  Future<Map<String, dynamic>?> getHotkeyPreference() async {
    final prefs = await readPreferences();
    final hotkey = prefs[StorageKeys.hotkey];
    if (hotkey is Map<String, dynamic>) {
      return hotkey;
    }
    return null;
  }

  /// Saves the hotkey preference to storage.
  ///
  /// Pass null to clear the hotkey.
  Future<void> saveHotkeyPreference(Map<String, dynamic>? hotkeyJson) async {
    final prefs = await readPreferences();
    if (hotkeyJson == null) {
      prefs.remove(StorageKeys.hotkey);
    } else {
      prefs[StorageKeys.hotkey] = hotkeyJson;
    }
    await writePreferences(prefs);
  }
}
