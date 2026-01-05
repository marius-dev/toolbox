import '../../core/services/tool_discovery_service.dart';
import '../models/tool.dart';

class ToolUseCases {
  final ToolDiscoveryService _discoveryService;

  ToolUseCases(this._discoveryService);

  Future<List<Tool>> discoverTools({bool forceRefresh = false}) {
    return _discoveryService.discoverTools(forceRefresh: forceRefresh);
  }

  Future<Tool> discoverTool(ToolId id, {bool forceRefresh = false}) {
    return _discoveryService.discoverTool(id, forceRefresh: forceRefresh);
  }

  Future<void> launchTool(Tool tool, {String? targetPath}) {
    return _discoveryService.launchTool(tool, targetPath: targetPath);
  }
}
