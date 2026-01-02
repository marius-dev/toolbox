import 'package:flutter/foundation.dart';

import '../../core/di/service_locator.dart';
import '../../core/services/storage/workspace_storage_service.dart';
import '../../domain/models/workspace.dart';
import '../../domain/use_cases/workspace_use_cases.dart';

class WorkspaceProvider extends ChangeNotifier {
  static const String _defaultWorkspaceName = 'Main workspace';

  final WorkspaceUseCases _useCases;
  final WorkspaceStorageService _storage;

  WorkspaceProvider(this._useCases, this._storage);

  factory WorkspaceProvider.create() {
    return getIt<WorkspaceProvider>();
  }

  List<Workspace> _workspaces = [];
  bool _isLoading = false;
  String? _selectedWorkspaceId;
  bool _hasLoadedSelection = false;

  List<Workspace> get workspaces => List.unmodifiable(_workspaces);
  bool get isLoading => _isLoading;
  String? get selectedWorkspaceId => _selectedWorkspaceId;
  Workspace? get selectedWorkspace {
    final id = _selectedWorkspaceId;
    if (id == null) return null;
    try {
      return _workspaces.firstWhere((workspace) => workspace.id == id);
    } catch (_) {
      return null;
    }
  }

  bool get canDeleteWorkspace => _workspaces.length > 1;
  Workspace? get defaultWorkspace {
    try {
      return _workspaces.firstWhere((workspace) => workspace.isDefault);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadWorkspaces() async {
    _isLoading = true;
    notifyListeners();

    try {
      _workspaces = await _useCases.getAllWorkspaces();
      if (_workspaces.isEmpty) {
        final created = await _useCases.addWorkspace(
          name: _defaultWorkspaceName,
          isDefault: true,
        );
        _workspaces = [created];
      } else {
        await _ensureDefaultWorkspace();
      }
      await _enforceNameLimit();
      await _loadSelectedWorkspace();
      await _ensureSelection();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSelectedWorkspace(String workspaceId) async {
    if (_selectedWorkspaceId == workspaceId) return;
    _selectedWorkspaceId = workspaceId;
    await _storage.saveSelectedWorkspaceId(workspaceId);
    notifyListeners();
  }

  Future<Workspace> createWorkspace(String name) async {
    final sanitized = _sanitizeName(name);
    final resolvedName = sanitized.isEmpty ? _defaultWorkspaceName : sanitized;
    final workspace = await _useCases.addWorkspace(name: resolvedName);
    _workspaces = await _useCases.getAllWorkspaces();
    notifyListeners();
    return workspace;
  }

  Future<void> renameWorkspace(Workspace workspace, String name) async {
    if (workspace.isDefault) return;
    final sanitized = _sanitizeName(name);
    if (sanitized.isEmpty) return;
    if (sanitized == workspace.name) return;
    final updated = workspace.copyWith(name: sanitized);
    await _useCases.updateWorkspace(updated);
    final index = _workspaces.indexWhere(
      (element) => element.id == workspace.id,
    );
    if (index != -1) {
      _workspaces[index] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteWorkspace(String workspaceId) async {
    final target = _workspaces
        .where((workspace) => workspace.id == workspaceId)
        .toList();
    if (target.isNotEmpty && target.first.isDefault) {
      return;
    }
    await _useCases.deleteWorkspace(workspaceId);
    _workspaces = await _useCases.getAllWorkspaces();
    if (_workspaces.isEmpty) {
      final created = await _useCases.addWorkspace(
        name: _defaultWorkspaceName,
        isDefault: true,
      );
      _workspaces = [created];
    } else {
      await _ensureDefaultWorkspace();
    }
    if (!_workspaces.any((w) => w.id == _selectedWorkspaceId)) {
      final fallback = defaultWorkspace ?? _workspaces.first;
      _selectedWorkspaceId = fallback.id;
      await _storage.saveSelectedWorkspaceId(_selectedWorkspaceId);
    }
    notifyListeners();
  }

  Future<void> _loadSelectedWorkspace() async {
    if (_hasLoadedSelection) return;
    _hasLoadedSelection = true;
    _selectedWorkspaceId = await _storage.getSelectedWorkspaceId();
  }

  Future<void> _ensureSelection() async {
    if (_selectedWorkspaceId == null ||
        !_workspaces.any((w) => w.id == _selectedWorkspaceId)) {
      final fallback = defaultWorkspace ?? _workspaces.first;
      _selectedWorkspaceId = fallback.id;
      await _storage.saveSelectedWorkspaceId(_selectedWorkspaceId);
    }
  }

  Future<void> _ensureDefaultWorkspace() async {
    final defaults = _workspaces.where((workspace) => workspace.isDefault);
    if (defaults.isNotEmpty) {
      if (defaults.length == 1) return;
      final keeper = defaults.first;
      for (var i = 0; i < _workspaces.length; i++) {
        final workspace = _workspaces[i];
        if (workspace.id != keeper.id && workspace.isDefault) {
          final updated = workspace.copyWith(isDefault: false);
          _workspaces[i] = updated;
          await _useCases.updateWorkspace(updated);
        }
      }
      return;
    }

    final sorted = List<Workspace>.from(_workspaces)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final fallback = sorted.firstWhere(
      (workspace) =>
          workspace.name == _defaultWorkspaceName ||
          workspace.name == 'Default workspace',
      orElse: () => sorted.first,
    );
    final updatedFallback = fallback.copyWith(isDefault: true);
    await _useCases.updateWorkspace(updatedFallback);
    final index = _workspaces.indexWhere((w) => w.id == fallback.id);
    if (index != -1) {
      _workspaces[index] = updatedFallback;
    }
  }

  String _sanitizeName(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= Workspace.maxNameLength) {
      return trimmed;
    }
    return trimmed.substring(0, Workspace.maxNameLength).trimRight();
  }

  Future<void> _enforceNameLimit() async {
    if (_workspaces.isEmpty) return;
    for (var i = 0; i < _workspaces.length; i++) {
      final workspace = _workspaces[i];
      final sanitized =
          workspace.isDefault && workspace.name.length > Workspace.maxNameLength
          ? _defaultWorkspaceName
          : _sanitizeName(workspace.name);
      if (sanitized.isEmpty || sanitized == workspace.name) {
        continue;
      }
      final updated = workspace.copyWith(name: sanitized);
      _workspaces[i] = updated;
      await _useCases.updateWorkspace(updated);
    }
  }
}
