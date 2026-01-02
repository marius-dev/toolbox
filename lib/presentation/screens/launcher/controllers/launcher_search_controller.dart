import 'package:flutter/material.dart';

import '../../launcher_screen.dart';
import '../../../providers/project_provider.dart';

/// Controller responsible for search state management in the launcher.
///
/// Handles:
/// - Search field text and focus management
/// - Initial input insertion into search field
/// - Popup menu dismissal
/// - Search query updates to project provider
class LauncherSearchController {
  LauncherSearchController({
    required ProjectProvider projectProvider,
    required this.getCurrentContext,
    required this.isProjectsTabSelected,
    required this.isPreferencesShown,
  }) : _projectProvider = projectProvider;

  final ProjectProvider _projectProvider;
  final BuildContext Function() getCurrentContext;
  final bool Function() isProjectsTabSelected;
  final bool Function() isPreferencesShown;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  TextEditingController get searchController => _searchController;
  FocusNode get searchFocusNode => _searchFocusNode;

  /// Clean up the controller by disposing resources
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
  }

  /// Focus the search field, optionally inserting initial input
  void focusSearchField({String? initialInput}) {
    final context = getCurrentContext();

    if (!isProjectsTabSelected() || isPreferencesShown()) {
      return;
    }

    dismissPopupMenus();

    if (initialInput != null && initialInput.isNotEmpty) {
      _insertInitialSearchInput(initialInput);
    }

    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  /// Dismiss any open popup menus
  void dismissPopupMenus() {
    final context = getCurrentContext();
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route is! PopupRoute);
  }

  /// Insert text at the current cursor position or selection
  void _insertInitialSearchInput(String input) {
    final text = _searchController.text;
    final selection = _searchController.selection;

    final hasSelection = selection.isValid &&
        selection.start >= 0 &&
        selection.end <= text.length;

    final start = hasSelection ? selection.start : text.length;
    final end = hasSelection ? selection.end : text.length;

    final newText = text.replaceRange(start, end, input);
    final newSelection = TextSelection.collapsed(offset: start + input.length);

    _searchController.value = TextEditingValue(
      text: newText,
      selection: newSelection,
    );

    _projectProvider.setSearchQuery(newText);
  }

  /// Update the search query in the project provider
  void setSearchQuery(String query) {
    _projectProvider.setSearchQuery(query);
  }
}
