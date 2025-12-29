import 'package:flutter/material.dart';

import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';

class SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;

  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? Colors.black.withOpacity(0.2)
        : Colors.white.withOpacity(0.9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final accentColor = ThemeProvider.instance.accentColor;

    return Container(
      margin: CompactLayout.only(
        context,
        bottom: 10,
      ),
      padding: EdgeInsets.all(CompactLayout.value(context, 12)),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius:
            BorderRadius.circular(CompactLayout.value(context, 10)),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(CompactLayout.value(context, 6)),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(CompactLayout.value(context, 8)),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).iconTheme.color,
              size: 20,
            ),
          ),
          SizedBox(width: CompactLayout.value(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: CompactLayout.value(context, 2)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          SizedBox(width: CompactLayout.value(context, 10)),
          trailing,
        ],
      ),
    );
  }
}
