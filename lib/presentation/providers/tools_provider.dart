import 'package:flutter/foundation.dart';

import '../../core/services/storage_service.dart';
import '../../core/services/tool_discovery_service.dart';
import '../../domain/models/tool.dart';
import '../../domain/use_cases/tool_use_cases.dart';

class ToolsProvider extends ChangeNotifier {
  final ToolUseCases _useCases;
  final StorageService _storage = StorageService.instance;

  ToolsProvider(this._useCases);

  factory ToolsProvider.create() {
    return ToolsProvider(ToolUseCases(ToolDiscoveryService.instance));
  }

  List<Tool> _tools = [];
  bool _isLoading = false;
  ToolId? _defaultToolId;
  bool _hasLoadedDefault = false;

  List<Tool> get installed =>
      _tools.where((tool) => tool.isInstalled).toList(growable: false);
  List<Tool> get available =>
      _tools.where((tool) => !tool.isInstalled).toList(growable: false);

  bool get isLoading => _isLoading;

  int get installedCount => installed.length;
  ToolId? get defaultToolId => _defaultToolId;
  Tool? get defaultTool {
    if (_defaultToolId == null) return null;
    try {
      return _tools.firstWhere((t) => t.id == _defaultToolId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadTools({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tools = await _useCases.discoverTools(forceRefresh: forceRefresh);
      await _loadDefaultTool();
      await _ensureDefaultToolInstalled();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadTools(forceRefresh: true);

  Future<void> launch(Tool tool) async {
    await _useCases.launchTool(tool);
  }

  Future<void> setDefaultTool(ToolId? toolId) async {
    _defaultToolId = toolId;
    await _storage.saveDefaultToolId(toolId?.name);
    notifyListeners();
  }

  Future<void> _loadDefaultTool() async {
    if (_hasLoadedDefault) return;
    _hasLoadedDefault = true;

    final savedId = await _storage.getDefaultToolId();
    if (savedId != null) {
      try {
        _defaultToolId = ToolId.values.firstWhere((id) => id.name == savedId);
      } catch (_) {
        _defaultToolId = null;
      }
    }
  }

  Future<void> _ensureDefaultToolInstalled() async {
    if (installed.isEmpty) {
      if (_defaultToolId != null) {
        _defaultToolId = null;
        await _storage.saveDefaultToolId(null);
      }
      return;
    }

    final installedIds = installed.map((t) => t.id).toSet();
    if (_defaultToolId == null || !installedIds.contains(_defaultToolId)) {
      _defaultToolId = installed.first.id;
      await _storage.saveDefaultToolId(_defaultToolId!.name);
    }
  }
}
