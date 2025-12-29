import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/project.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';

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
      padding: CompactLayout.only(
        context,
        left: 18,
        top: 10,
        right: 18,
        bottom: 6,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 420;
          if (isStacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(context),
                SizedBox(height: CompactLayout.value(context, 6)),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildSortPicker(context),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: _buildSearchField(context)),
              SizedBox(width: CompactLayout.value(context, 6)),
              _buildSortPicker(context),
            ],
          );
        },
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
                size: CompactLayout.value(context, 16),
                color: Theme.of(context).iconTheme.color,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: CompactLayout.value(context, 36),
                minHeight: CompactLayout.value(context, 36),
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minHeight: CompactLayout.value(context, 32),
                        minWidth: CompactLayout.value(context, 32),
                      ),
                      icon: Icon(
                        Icons.close,
                        size: CompactLayout.value(context, 14),
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: CompactLayout.value(context, 10),
                vertical: CompactLayout.value(context, 6),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(CompactLayout.value(context, 10)),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(CompactLayout.value(context, 10)),
                borderSide: BorderSide(color: accentColor, width: 1.2),
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
        borderRadius: BorderRadius.circular(CompactLayout.value(context, 10)),
      ),
      constraints:
          BoxConstraints(minHeight: CompactLayout.value(context, 40)),
      child: PopupMenuButton<SortOption>(
        initialValue: currentSort,
        padding: EdgeInsets.zero,
        color: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(CompactLayout.value(context, 10)),
          side: BorderSide(color: borderColor),
        ),
        onSelected: onSortChanged,
        itemBuilder: (context) => SortOption.values
            .map((option) => _buildSortMenuItem(context, option))
            .toList(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: CompactLayout.value(context, 10),
            vertical: CompactLayout.value(context, 6),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sort_rounded,
                size: CompactLayout.value(context, 14),
                color: Theme.of(context).iconTheme.color,
              ),
              SizedBox(width: CompactLayout.value(context, 6)),
              Text(
                currentSort.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(
                    fontSize: CompactLayout.value(context, 12),
                  ),
              ),
              SizedBox(width: CompactLayout.value(context, 4)),
              Icon(
                Icons.keyboard_arrow_down,
                size: CompactLayout.value(context, 14),
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
      padding: EdgeInsets.symmetric(
        horizontal: CompactLayout.value(context, 10),
        vertical: CompactLayout.value(context, 5),
      ),
      child: Row(
        children: [
          if (isSelected)
            Icon(
              Icons.check,
              size: CompactLayout.value(context, 14),
              color: accentColor,
            )
          else
            Icon(
              Icons.check,
              size: CompactLayout.value(context, 14),
              color: Colors.transparent,
            ),
          SizedBox(width: CompactLayout.value(context, 6)),
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
