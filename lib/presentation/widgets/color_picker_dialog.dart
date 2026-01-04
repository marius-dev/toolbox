import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_extensions.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    required this.onApply,
    required this.onCancel,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
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
    final textPrimary = theme.textTheme.bodyLarge!.color!;
    final textSecondary = theme.textTheme.bodyMedium!.color!;

    return Dialog(
      backgroundColor: background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.compactValue(DesignTokens.radiusLg)),
        side: BorderSide(color: borderColor),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.compactValue(24),
          context.compactValue(18),
          context.compactValue(24),
          context.compactValue(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select accent color',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                    background,
                  ),
                  borderRadius: BorderRadius.circular(context.compactValue(DesignTokens.radiusMd)),
                  border: Border.all(color: borderColor),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.compactValue(6),
                  vertical: context.compactValue(6),
                ),
                child: BlockPicker(
                  pickerColor: _selectedColor,
                  availableColors: AppColors.accentPresets,
                  onColorChanged: (color) {
                    setState(() => _selectedColor = color);
                    widget.onColorChanged(color);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text('Cancel', style: TextStyle(color: textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.compactValue(DesignTokens.radiusSm)),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
