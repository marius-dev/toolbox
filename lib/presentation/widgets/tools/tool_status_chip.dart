import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';

class ToolStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const ToolStatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: context.compactValue(8)),
      padding: EdgeInsets.symmetric(
        horizontal: context.compactValue(7),
        vertical: context.compactValue(3),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: context.compactValue(13), color: color),
            SizedBox(width: context.compactValue(4)),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: context.compactValue(10),
            ),
          ),
        ],
      ),
    );
  }
}
