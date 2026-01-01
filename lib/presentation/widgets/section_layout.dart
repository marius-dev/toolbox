import 'package:flutter/material.dart';

import '../../core/utils/compact_layout.dart';
import 'glass_button.dart';

class SectionLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onBack;
  final IconData buttonIcon;
  final String buttonTooltip;
  final EdgeInsetsGeometry padding;
  final bool expandBody;

  const SectionLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBack,
    this.buttonIcon = Icons.arrow_back_ios_new_rounded,
    this.buttonTooltip = 'Back to launcher',
    this.padding = EdgeInsets.zero,
    this.expandBody = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelColor = textTheme.bodyMedium?.color ?? Colors.black;
    final secondaryColor = labelColor.withOpacity(0.8);

    final body = expandBody ? Expanded(child: child) : child;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: buttonTooltip,
                child: GlassButton(
                  icon: buttonIcon,
                  tooltip: buttonTooltip,
                  onPressed: onBack,
                ),
              ),
              SizedBox(width: CompactLayout.value(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ) ??
                          const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: CompactLayout.value(context, 4)),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                            color: secondaryColor,
                          ) ??
                          TextStyle(color: secondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: CompactLayout.value(context, 12)),
          body,
        ],
      ),
    );
  }
}
