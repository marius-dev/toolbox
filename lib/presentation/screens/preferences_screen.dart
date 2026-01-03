import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/theme_provider.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/hotkey_picker.dart';
import '../widgets/section_layout.dart';
import '../widgets/settings_tile.dart';

class PreferencesScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRescan;

  const PreferencesScreen({
    super.key,
    required this.onBack,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.compactPaddingOnly(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SectionLayout(
              onBack: onBack,
              title: 'Preferences',
              subtitle: 'Customize how the launcher looks and behaves.',
              padding: context.compactPadding(horizontal: 18),
              child: ListView(
                padding: EdgeInsets.only(
                  bottom: context.compactValue(16),
                ),
                children: [
                  const HotkeyPicker(),
                  SizedBox(height: context.compactValue(10)),
                  _buildThemeToggle(context),
                  SizedBox(height: context.compactValue(10)),
                  _buildScaleTile(context),
                  SizedBox(height: context.compactValue(10)),
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
    final themeProvider = getIt<ThemeProvider>();
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        final accentColor = themeProvider.accentColor;
        final isDarkTheme = context.isDark;
        final borderColor = isDarkTheme
            ? Colors.white.withOpacity(0.12)
            : Colors.black.withOpacity(0.08);

        return SettingsTile(
          title: 'Appearance',
          subtitle: 'Follow system or choose light/dark surfaces',
          icon: Icons.light_mode,
          trailing: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.compactValue(6),
              vertical: context.compactValue(4),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                context.compactValue(10),
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
                minWidth: context.compactValue(64),
                minHeight: context.compactValue(30),
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

  Widget _buildScaleTile(BuildContext context) {
    final themeProvider = getIt<ThemeProvider>();
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        final isDarkTheme = context.isDark;

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
                      fontSize: context.compactValue(12),
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
    final themeProvider = getIt<ThemeProvider>();
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        final accentColor = context.accentColor;
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
    final isDark = context.isDark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return InkWell(
      onTap: () => _showColorPicker(context),
      borderRadius: BorderRadius.circular(context.compactValue(10)),
      child: Container(
        width: context.compactValue(34),
        height: context.compactValue(34),
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(context.compactValue(10)),
          border: Border.all(color: borderColor),
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    final themeProvider = getIt<ThemeProvider>();
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
