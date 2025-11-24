import 'package:flutter/foundation.dart';

import '../../core/services/tool_discovery_service.dart';
import '../../domain/models/tool.dart';
import '../../domain/use_cases/tool_use_cases.dart';

class ToolsProvider extends ChangeNotifier {
  final ToolUseCases _useCases;

  ToolsProvider(this._useCases);

  factory ToolsProvider.create() {
    return ToolsProvider(ToolUseCases(ToolDiscoveryService.instance));
  }

  List<Tool> _tools = [];
  bool _isLoading = false;

  List<Tool> get installed =>
      _tools.where((tool) => tool.isInstalled).toList(growable: false);
  List<Tool> get available =>
      _tools.where((tool) => !tool.isInstalled).toList(growable: false);

  bool get isLoading => _isLoading;

  int get installedCount => installed.length;

  Future<void> loadTools({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _tools = await _useCases.discoverTools(forceRefresh: forceRefresh);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadTools(forceRefresh: true);

  Future<void> launch(Tool tool) async {
    await _useCases.launchTool(tool);
  }
}
