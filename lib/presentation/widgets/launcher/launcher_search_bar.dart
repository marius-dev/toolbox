import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/compact_layout.dart';
import '../app_menu.dart';

part 'launcher_search_suffix.dart';

class LauncherSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateNext;
  final VoidCallback? onSearchFocus;
  final VoidCallback? onAddProject;
  final VoidCallback? onImportFromGit;

  const LauncherSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    this.focusNode,
    this.onNavigateNext,
    this.onSearchFocus,
    this.onAddProject,
    this.onImportFromGit,
  });

  @override
  Widget build(BuildContext context) {
    final padding = CompactLayout.symmetric(
      context,
      horizontal: 10,
      vertical: 12,
    );
    final hasActions = onAddProject != null || onImportFromGit != null;

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Expanded(child: _buildSearchField(context, hasActions))],
          );
        },
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, bool hasActions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final fillColor = isDark
        ? Colors.black.withOpacity(0.5)
        : Colors.white.withOpacity(0.9);
    final borderColor = baseColor.withOpacity(isDark ? 0.26 : 0.12);
    final accentColor = ThemeProvider.instance.accentColor;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                onNavigateNext?.call();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                controller.clear();
                onSearchChanged('');
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          onFocusChange: (hasFocus) {
            if (hasFocus) onSearchFocus?.call();
          },
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            onChanged: onSearchChanged,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.2),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              hintText: 'Type to search ...',
              hintStyle: TextStyle(color: baseColor.withOpacity(0.5)),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: baseColor.withOpacity(0.7),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              suffixIcon: (value.text.isNotEmpty || hasActions)
                  ? _SearchFieldSuffix(
                      hasQuery: value.text.isNotEmpty,
                      onClear: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                      showActions: hasActions,
                      onAddProject: onAddProject,
                      onImportFromGit: onImportFromGit,
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 48,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: accentColor, width: 1.4),
              ),
            ),
          ),
        );
      },
    );
  }
}
