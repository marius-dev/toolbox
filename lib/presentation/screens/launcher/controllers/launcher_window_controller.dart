import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/services/window_service.dart';

/// Controller responsible for window management in the launcher.
///
/// Handles:
/// - Window visibility state tracking
/// - Auto-hide behavior on blur/focus events
/// - Window show/hide event handling
/// - Metadata sync trigger on window visibility
class LauncherWindowController extends ChangeNotifier with WindowListener {
  LauncherWindowController({
    required WindowService windowService,
    required this.onMetadataSync,
  }) : _windowService = windowService;

  final WindowService _windowService;
  final VoidCallback onMetadataSync;

  bool _wasHidden = false;
  bool get wasHidden => _wasHidden;

  /// Initialize the controller by registering window event listeners
  void initialize() {
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowBlur() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_windowService.shouldAutoHideOnBlur) return;
      _wasHidden = true;
      _windowService.hide();
      notifyListeners();
    });
  }

  @override
  void onWindowFocus() {
    _handleWindowVisible();
  }

  @override
  void onWindowEvent(String eventName) {
    if (eventName == 'hide') {
      _wasHidden = true;
      notifyListeners();
      return;
    }
    if (eventName == 'show') {
      _handleWindowVisible();
    }
  }

  void _handleWindowVisible() {
    if (!_wasHidden) return;
    _wasHidden = false;
    notifyListeners();

    // Trigger metadata sync callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onMetadataSync();
    });
  }
}
