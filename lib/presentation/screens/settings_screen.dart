import 'package:flutter/material.dart';

import '../../core/theme/glass_style.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/hotkey_picker.dart';
import '../widgets/section_layout.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRescan;

  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: CompactLayout.only(context, top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SectionLayout(
              onBack: onBack,
              title: 'Settings',
              subtitle: 'Customize how the launcher looks and behaves.',
              padding: CompactLayout.symmetric(context, horizontal: 18),
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: CompactLayout.value(context, 16),
                ),
                children: [
                  const HotkeyPicker(),
                  SizedBox(height: CompactLayout.value(context, 10)),
                  _buildThemeToggle(context),
                  SizedBox(height: CompactLayout.value(context, 10)),
                  _buildGlassStyleTile(context),
                  SizedBox(height: CompactLayout.value(context, 10)),
                  _buildScaleTile(context),
                  SizedBox(height: CompactLayout.value(context, 10)),
                  _buildAccentColorPicker(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final themeProvider = ThemeProvider.instance;
        final accentColor = themeProvider.accentColor;
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        final borderColor = isDarkTheme
            ? Colors.white.withOpacity(0.12)
            : Colors.black.withOpacity(0.08);

        return SettingsTile(
          title: 'Appearance',
          subtitle: 'Follow system or choose light/dark surfaces',
          icon: Icons.light_mode,
          trailing: Container(
            padding: EdgeInsets.symmetric(
              horizontal: CompactLayout.value(context, 6),
              vertical: CompactLayout.value(context, 4),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                CompactLayout.value(context, 10),
              ),
              border: Border.all(color: borderColor),
            ),
            child: ToggleButtons(
              isSelected: [
                themeProvider.themeMode == ThemeMode.system,
                themeProvider.themeMode == ThemeMode.light,
                themeProvider.themeMode == ThemeMode.dark,
              ],
              onPressed: (index) {
                const modes = [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark,
                ];
                themeProvider.setThemeMode(modes[index]);
              },
              borderRadius: BorderRadius.circular(10),
              renderBorder: false,
              constraints: BoxConstraints(
                minWidth: CompactLayout.value(context, 64),
                minHeight: CompactLayout.value(context, 30),
              ),
              color: Theme.of(context).textTheme.bodyMedium!.color,
              selectedColor: accentColor,
              fillColor: accentColor.withOpacity(isDarkTheme ? 0.18 : 0.14),
              children: const [Text('System'), Text('Light'), Text('Dark')],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassStyleTile(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final themeProvider = ThemeProvider.instance;
        final accentColor = themeProvider.accentColor;
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        final borderColor = isDarkTheme
            ? Colors.white.withOpacity(0.12)
            : Colors.black.withOpacity(0.08);

        return SettingsTile(
          title: 'Glass finish',
          subtitle: 'Choose between a clear or tinted glass base',
          icon: Icons.opacity,
          trailing: Container(
            padding: EdgeInsets.symmetric(
              horizontal: CompactLayout.value(context, 6),
              vertical: CompactLayout.value(context, 4),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                CompactLayout.value(context, 10),
              ),
              border: Border.all(color: borderColor),
            ),
            child: ToggleButtons(
              isSelected: [
                themeProvider.glassStyle == GlassStyle.clear,
                themeProvider.glassStyle == GlassStyle.tinted,
              ],
              onPressed: (index) {
                final options = [GlassStyle.clear, GlassStyle.tinted];
                themeProvider.setGlassStyle(options[index]);
              },
              borderRadius: BorderRadius.circular(10),
              renderBorder: false,
              constraints: BoxConstraints(
                minWidth: CompactLayout.value(context, 64),
                minHeight: CompactLayout.value(context, 30),
              ),
              color: Theme.of(context).textTheme.bodyMedium!.color,
              selectedColor: accentColor,
              fillColor: accentColor.withOpacity(isDarkTheme ? 0.18 : 0.14),
              children: const [Text('Clear'), Text('Tinted')],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaleTile(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final themeProvider = ThemeProvider.instance;
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

        return SettingsTile(
          title: 'App size',
          subtitle: 'Scale the UI',
          icon: Icons.zoom_out_map,
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: themeProvider.scaleFactor,
              iconEnabledColor: themeProvider.accentColor,
              dropdownColor: isDarkTheme ? Colors.grey[850] : Colors.white,
              isDense: true,
              alignment: Alignment.centerRight,
              underline: const SizedBox.shrink(),
              items: ThemeProvider.scaleOptions.map((scale) {
                final label = '${(scale * 100).round()}%';
                return DropdownMenuItem<double>(
                  value: scale,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: CompactLayout.value(context, 12),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setScaleFactor(value);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccentColorPicker(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final accentColor = ThemeProvider.instance.accentColor;
        final colorHex =
            '#${accentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

        return SettingsTile(
          title: 'Accent color',
          subtitle: colorHex,
          icon: Icons.color_lens,
          trailing: _buildColorButton(context, accentColor),
        );
      },
    );
  }

  Widget _buildColorButton(BuildContext context, Color currentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(CompactLayout.value(context, 10)),
      child: Container(
        width: CompactLayout.value(context, 34),
        height: CompactLayout.value(context, 34),
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(CompactLayout.value(context, 10)),
          border: Border.all(color: borderColor),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final themeProvider = ThemeProvider.instance;
    Color tempColor = themeProvider.accentColor;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: ColorPickerDialog(
          initialColor: themeProvider.accentColor,
          onColorChanged: (color) => tempColor = color,
          onApply: () {
            themeProvider.setAccentColor(tempColor);
            Navigator.pop(context);
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
