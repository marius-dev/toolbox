import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/project.dart';
import '../../core/theme/theme_provider.dart';

class SearchSortBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final SortOption currentSort;
  final ValueChanged<SortOption> onSortChanged;
  final FocusNode? focusNode;
  final VoidCallback? onNavigateNext;
  final VoidCallback? onSearchFocus;

  const SearchSortBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.currentSort,
    required this.onSortChanged,
    this.focusNode,
    this.onNavigateNext,
    this.onSearchFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(child: _buildSearchField(context)),
          const SizedBox(width: 10),
          _buildSortPicker(context),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final accentColor = ThemeProvider.instance.accentColor;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              onNavigateNext?.call();
              return KeyEventResult.handled;
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
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: panelColor,
              hintText: 'Search by name or path',
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: Theme.of(context).iconTheme.color,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        minWidth: 36,
                      ),
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final bgColor = isDark ? Colors.black.withOpacity(0.7) : panelColor;

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(minHeight: 44),
      child: PopupMenuButton<SortOption>(
        initialValue: currentSort,
        padding: EdgeInsets.zero,
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        onSelected: onSortChanged,
        itemBuilder: (context) => SortOption.values
            .map((option) => _buildSortMenuItem(context, option))
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.sort_rounded,
                size: 16,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 8),
              Text(
                currentSort.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontSize: 12),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<SortOption> _buildSortMenuItem(
    BuildContext context,
    SortOption option,
  ) {
    final accentColor = ThemeProvider.instance.accentColor;
    final isSelected = option == currentSort;

    return PopupMenuItem(
      value: option,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          if (isSelected)
            Icon(Icons.check, size: 16, color: accentColor)
          else
            const Icon(Icons.check, size: 16, color: Colors.transparent),
          const SizedBox(width: 8),
          Text(
            option.displayName,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? accentColor
                  : Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
        ],
      ),
    );
  }
}
