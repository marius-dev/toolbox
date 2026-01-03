import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controller responsible for handling keyboard events in the launcher.
///
/// Handles:
/// - Raw keyboard event processing
/// - Alphanumeric key capture for search auto-focus
/// - Keyboard shortcut detection
/// - Prevention of duplicate focus scheduling
class LauncherKeyboardController {
  LauncherKeyboardController({
    required this.onFocusSearchWithInput,
    required this.getCurrentContext,
    required this.isPreferencesShown,
    required this.isProjectsTabSelected,
    required this.isSearchFocused,
  });

  final void Function({String? initialInput}) onFocusSearchWithInput;
  final BuildContext Function() getCurrentContext;
  final bool Function() isPreferencesShown;
  final bool Function() isProjectsTabSelected;
  final bool Function() isSearchFocused;

  bool _isSearchFocusScheduled = false;
  String? _pendingSearchInitialInput;

  /// Initialize the controller by registering keyboard listeners
  void initialize() {
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  /// Clean up the controller by removing keyboard listeners
  void dispose() {
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    final context = getCurrentContext();
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    if (event is! RawKeyDownEvent) return;

    // Don't process keyboard events when preferences are shown
    if (isPreferencesShown()) return;

    // Only handle keyboard events on the projects tab
    if (!isProjectsTabSelected()) return;

    // Don't process if search is already focused
    if (isSearchFocused()) return;

    // Don't handle keys with modifiers
    final hasModifiers =
        event.isControlPressed || event.isMetaPressed || event.isAltPressed;
    if (hasModifiers) return;

    // Don't handle if an editable widget already has focus
    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    if (focusedWidget is EditableText) return;

    // Check if the key is alphanumeric
    final character = event.character;
    final isAlphanumeric =
        character != null && RegExp(r'^[a-zA-Z0-9]$').hasMatch(character);
    if (!isAlphanumeric) return;

    // Prevent duplicate focus scheduling
    if (_isSearchFocusScheduled) return;

    // Schedule search focus with the typed character
    _pendingSearchInitialInput = character;
    _isSearchFocusScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isSearchFocusScheduled = false;
      final initialInput = _pendingSearchInitialInput;
      _pendingSearchInitialInput = null;

      if (initialInput == null || initialInput.isEmpty) return;
      onFocusSearchWithInput(initialInput: initialInput);
    });
  }
}
