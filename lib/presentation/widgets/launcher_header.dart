import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';
import 'glass_button.dart';

class LauncherHeader extends StatelessWidget {
  final VoidCallback onSettingsPressed;
  final VoidCallback onAddProject;

  const LauncherHeader({
    Key? key,
    required this.onSettingsPressed,
    required this.onAddProject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final accentColor = ThemeProvider.instance.accentColor;
        final textColor = Theme.of(context).textTheme.bodyLarge!.color!;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildLogo(accentColor),
                  const SizedBox(width: 12),
                  Text(
                    'Marius\'s toolbox',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_lighten(accentColor, 0.12), accentColor],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 18),
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
