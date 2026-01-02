import 'package:flutter/material.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/compact_layout.dart';
import '../../../core/utils/string_utils.dart';
import '../../../domain/models/tool.dart';

class ToolDetails extends StatelessWidget {
  final Tool tool;
  final Color textColor;
  final Color mutedText;

  const ToolDetails({
    super.key,
    required this.tool,
    required this.textColor,
    required this.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    final displayPath = tool.path != null
        ? StringUtils.replaceHomeWithTilde(tool.path!)
        : null;
    final pathText = displayPath != null
        ? StringUtils.ellipsisStart(displayPath, maxLength: 60)
        : 'Path not found';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tool.name,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: context.compactValue(13),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: context.compactValue(6)),
        Row(
          children: [
            Icon(
              Icons.folder_rounded,
              size: context.compactValue(15),
              color: Theme.of(context).iconTheme.color,
            ),
            SizedBox(width: context.compactValue(6)),
            Expanded(
              child: Text(
                pathText,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: mutedText.withOpacity(0.8),
                  fontSize: context.compactValue(11),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
