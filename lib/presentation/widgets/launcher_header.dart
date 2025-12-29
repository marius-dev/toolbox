import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/compact_layout.dart';
import 'glass_button.dart';

class LauncherHeader extends StatelessWidget {
  final VoidCallback onSettingsPressed;
  final VoidCallback onAddProject;

  const LauncherHeader({
    super.key,
    required this.onSettingsPressed,
    required this.onAddProject,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final accentColor = ThemeProvider.instance.accentColor;
        final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
        final muted = Theme.of(context).textTheme.bodyMedium!.color!;

        return Container(
          padding: CompactLayout.only(
            context,
            left: 16,
            top: 14,
            right: 16,
            bottom: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildLogo(accentColor, context),
                  SizedBox(width: CompactLayout.value(context, 10)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projects toolbox',
                        style: TextStyle(
                          fontSize: CompactLayout.value(context, 17),
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: CompactLayout.value(context, 2)),
                      Text(
                        'Launch apps, scripts & tools from one place',
                        style: TextStyle(
                          fontSize: CompactLayout.value(context, 11),
                          color: muted.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  GlassButton(
                    icon: Icons.add,
                    onPressed: onAddProject,
                    size: _compactButtonSize(context),
                    tooltip: 'Add Project',
                  ),
                  SizedBox(width: CompactLayout.value(context, 6)),
                  GlassButton(
                    icon: Icons.card_giftcard_rounded,
                    onPressed: () {},
                    size: _compactButtonSize(context),
                  ),
                  SizedBox(width: CompactLayout.value(context, 6)),
                  GlassButton(
                    icon: Icons.help_outline_rounded,
                    onPressed: () {},
                    size: _compactButtonSize(context),
                  ),
                  SizedBox(width: CompactLayout.value(context, 6)),
                  GlassButton(
                    icon: Icons.settings_rounded,
                    onPressed: onSettingsPressed,
                    size: _compactButtonSize(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo(Color accentColor, BuildContext context) {
    return Container(
      width: CompactLayout.value(context, 38),
      height: CompactLayout.value(context, 38),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lighten(accentColor, 0.25), accentColor],
        ),
        borderRadius:
            BorderRadius.circular(CompactLayout.value(context, 10)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.bolt_rounded,
        color: Colors.white,
        size: CompactLayout.value(context, 16),
      ),
    );
  }
 
  double _compactButtonSize(BuildContext context) =>
      CompactLayout.value(context, 28);

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
