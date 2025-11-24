import 'package:flutter/material.dart';
import '../../core/theme/theme_provider.dart';

class TabBarWidget extends StatefulWidget {
  const TabBarWidget({Key? key}) : super(key: key);

  @override
  State<TabBarWidget> createState() => _TabBarWidgetState();
}

class _TabBarWidgetState extends State<TabBarWidget> {
  String _selectedTab = 'Projects';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeProvider.instance,
      builder: (context, _) {
        final isDark = ThemeProvider.instance.isDarkMode;
        final panelColor = isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.white.withOpacity(0.9);
        final surfaceOutline = isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.04);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: surfaceOutline, width: 1),
          ),
          child: Row(
            children: [
              _buildTab('Tools', false, badge: '1'),
              _buildTab('Projects', true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String label, bool isActive, {String? badge}) {
    final accentColor = ThemeProvider.instance.accentColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge!.color!;
    final textSecondary = Theme.of(context).textTheme.bodyMedium!.color!;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = label),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor.withOpacity(0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? textPrimary : textSecondary,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
