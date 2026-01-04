import 'package:flutter/material.dart';
import '../../core/constants/workspace_icons.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_extensions.dart';

class IconPickerDialog extends StatefulWidget {
  final int initialIconIndex;

  const IconPickerDialog({super.key, required this.initialIconIndex});

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late int _selectedIconIndex;

  @override
  void initState() {
    super.initState();
    _selectedIconIndex = widget.initialIconIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDark;
    final accentColor = context.accentColor;
    final palette = GlassStylePalette(
      style: context.glassStyle,
      isDark: isDark,
      accentColor: accentColor,
    );
    final borderColor = palette.borderColor;
    final background = solidDialogBackground(palette, theme);

    return AlertDialog(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.compactValue(28),
        vertical: context.compactValue(18),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          context.compactValue(DesignTokens.radiusLg),
        ),
        side: BorderSide(color: borderColor),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        context.compactValue(24),
        context.compactValue(18),
        context.compactValue(24),
        0,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        context.compactValue(24),
        context.compactValue(14),
        context.compactValue(24),
        context.compactValue(10),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        context.compactValue(18),
        0,
        context.compactValue(18),
        context.compactValue(12),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose icon', style: theme.textTheme.titleLarge),
          SizedBox(height: context.compactValue(4)),
          Text(
            'Select an icon to represent your workspace.',
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.textTheme.bodySmall!.color!.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: context.compactValue(400),
        height: context.compactValue(300),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: context.compactValue(8),
            crossAxisSpacing: context.compactValue(8),
            childAspectRatio: 1,
          ),
          itemCount: WorkspaceIcons.iconCount,
          itemBuilder: (context, index) {
            final icon = WorkspaceIcons.icons[index];
            final isSelected = index == _selectedIconIndex;

            return InkWell(
              onTap: () => setState(() => _selectedIconIndex = index),
              borderRadius: BorderRadius.circular(
                context.compactValue(DesignTokens.radiusSm),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: isDark ? 0.2 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    context.compactValue(DesignTokens.radiusSm),
                  ),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : borderColor.withValues(alpha: 0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: context.compactValue(24),
                  color: isSelected ? accentColor : theme.iconTheme.color,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.textTheme.bodyMedium!.color),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIconIndex),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                context.compactValue(DesignTokens.radiusSm),
              ),
            ),
          ),
          child: const Text(
            'Select',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
