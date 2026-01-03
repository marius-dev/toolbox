import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import 'tool_status_chip.dart';

class ToolStatusGroup extends StatelessWidget {
  final bool isInstalled;
  final bool isDefault;
  final Color accentColor;

  const ToolStatusGroup({
    super.key,
    required this.isInstalled,
    required this.isDefault,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (!isInstalled) {
      chips.add(
        ToolStatusChip(
          label: 'Not installed',
          color: Colors.red,
          background: Colors.red.withOpacity(0.16),
        ),
      );
    }

    if (isDefault) {
      chips.add(
        ToolStatusChip(
          label: 'Default',
          color: accentColor,
          icon: Icons.check_rounded,
          background: accentColor.withOpacity(0.16),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) SizedBox(width: context.compactValue(6)),
          chips[i],
        ],
      ],
    );
  }
}
