import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
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
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildLogo(accentColor),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projects toolbox',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Launch apps, scripts & tools from one place',
                        style: TextStyle(
                          fontSize: 12,
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
                    tooltip: 'Add Project',
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    icon: Icons.card_giftcard_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    icon: Icons.help_outline_rounded,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    icon: Icons.settings_rounded,
                    onPressed: onSettingsPressed,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo(Color accentColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lighten(accentColor, 0.25), accentColor],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
