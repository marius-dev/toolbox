import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/hotkey_picker.dart';
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
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const HotkeyPicker(),
              const SizedBox(height: 12),
              _buildToolsRescanTile(context),
              const SizedBox(height: 12),
              _buildThemeToggle(context),
              const SizedBox(height: 12),
              _buildAccentColorPicker(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: onBack,
          ),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsRescanTile(BuildContext context) {
    final accentColor = ThemeProvider.instance.accentColor;

    return SettingsTile(
      title: 'Rescan tools',
      subtitle: 'Redetect editors and viewers installed on this device',
      icon: Icons.refresh,
      trailing: TextButton(
        onPressed: onRescan,
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        child: const Text('Rescan'),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
              constraints:
                  const BoxConstraints(minWidth: 68, minHeight: 34),
              color: Theme.of(context).textTheme.bodyMedium!.color,
              selectedColor: accentColor,
              fillColor: accentColor.withOpacity(isDarkTheme ? 0.18 : 0.14),
              children: const [
                Text('System'),
                Text('Light'),
                Text('Dark'),
              ],
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(8),
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
