import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

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
    final accentColor = context.accentColor;
    final isDarkTheme = context.isDark;
    final backgroundColor = isDarkTheme
        ? const Color(0xFF181A24)
        : Colors.white;
    final borderColor = isDarkTheme
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    return Container(
      margin: context.compactPaddingOnly(bottom: 10),
      padding: EdgeInsets.all(context.compactValue(12)),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(context.compactValue(10)),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (isDarkTheme)
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.compactValue(6)),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(
                context.compactValue(8),
              ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).iconTheme.color,
              size: 20,
            ),
          ),
          SizedBox(width: context.compactValue(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: context.compactValue(2)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          SizedBox(width: context.compactValue(10)),
          trailing,
        ],
      ),
    );
  }
}
