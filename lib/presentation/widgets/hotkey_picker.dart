import 'package:flutter/material.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../core/services/hotkey_service.dart';
import '../../core/services/window_service.dart';
import '../../core/theme/theme_provider.dart';
import 'settings_tile.dart';

class HotkeyPicker extends StatefulWidget {
  const HotkeyPicker({super.key});

  @override
  State<HotkeyPicker> createState() => _HotkeyPickerState();
}

class _HotkeyPickerState extends State<HotkeyPicker> {
  HotKey? _currentHotKey;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _currentHotKey = HotkeyService.instance.currentHotKey;
    HotkeyService.instance.addListener(_updateHotkey);
    ThemeProvider.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    HotkeyService.instance.removeListener(_updateHotkey);
    ThemeProvider.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _updateHotkey() =>
      setState(() => _currentHotKey = HotkeyService.instance.currentHotKey);
  void _rebuild() => setState(() {});

  String _formatHotkeySymbols(HotKey hotKey) {
    final mods = (hotKey.modifiers ?? []).map((m) => _toSymbol(m.keyLabel));
    return [...mods, _toSymbol(hotKey.keyCode.keyLabel)].join(' ');
  }

  String _toSymbol(String label) {
    final l = label.toLowerCase();

    // Modifiers
    if (l.contains('command') ||
        l.contains('meta') ||
        l == 'cmd' ||
        l == 'super') {
      return '⌘';
    }
    if (l.contains('shift')) return '⇧';
    if (l.contains('option') || l == 'alt') return '⌥';
    if (l.contains('control') || l == 'ctrl') return '⌃';
    if (l.contains('caps')) return '⇪';
    if (l.contains('fn')) return 'fn';

    // Special keys
    const keyMap = {
      'enter': '↩',
      'return': '↩',
      'escape': '⎋',
      'esc': '⎋',
      'backspace': '⌫',
      'delete': '⌦',
      'tab': '⇥',
      'space': '␣',
      'spacebar': '␣',
      'up': '↑',
      'arrow up': '↑',
      'down': '↓',
      'arrow down': '↓',
      'left': '←',
      'arrow left': '←',
      'right': '→',
      'arrow right': '→',
      'page up': '⇞',
      'page down': '⇟',
      'home': '↖',
      'end': '↘',
      'minus': '−',
      '-': '−',
      'plus': '+',
      '+': '+',
      'equal': '=',
      '=': '=',
      'slash': '/',
      '/': '/',
      'backslash': '⧵',
      '\\': '⧵',
      'comma': ',',
      ',': ',',
      'period': '.',
      '.': '.',
      'semicolon': ';',
      ';': ';',
      'quote': ''', '\'': ''',
      'grave': '`',
      '`': '`',
      'bracket left': '[',
      '[': '[',
      'bracket right': ']',
      ']': ']',
    };

    return keyMap[l] ?? (label.length == 1 ? label.toUpperCase() : label);
  }

  Future<void> _saveHotkey(HotKey hotKey) async {
    await HotkeyService.instance.setHotkey(hotKey);
    await WindowService.instance.show();
  }

  Future<void> _clearHotkey() async {
    setState(() => _isRecording = false);
    await HotkeyService.instance.setHotkey(null);
  }

  Future<void> _handleRecordedHotkey(HotKey hotKey) async {
    setState(() => _isRecording = false);
    await _saveHotkey(hotKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textColor = theme.textTheme.bodyMedium?.color;

    return SettingsTile(
      title: 'Keyboard shortcut',
      subtitle: _currentHotKey == null ? 'Click to set a shortcut' : '',
      icon: Icons.keyboard_rounded,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Stack(
          children: [
            InkWell(
              onTap: () => setState(() => _isRecording = true),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isRecording
                        ? theme.colorScheme.primary.withOpacity(0.45)
                        : borderColor,
                    width: _isRecording ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _isRecording
                            ? 'Press keys...'
                            : (_currentHotKey != null
                                  ? _formatHotkeySymbols(_currentHotKey!)
                                  : 'Not set'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: (_currentHotKey != null || _isRecording)
                              ? textColor
                              : textColor?.withOpacity(0.5),
                          fontWeight: _currentHotKey != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                          letterSpacing: _currentHotKey != null ? 0.5 : 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_currentHotKey != null) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: _clearHotkey,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: textColor?.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_isRecording)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Opacity(
                    opacity: 0,
                    child: HotKeyRecorder(
                      onHotKeyRecorded: _handleRecordedHotkey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
