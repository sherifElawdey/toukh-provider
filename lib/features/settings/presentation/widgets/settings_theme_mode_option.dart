import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class SettingsThemeModeOption extends StatelessWidget {
  const SettingsThemeModeOption({
    super.key,
    required this.icon,
    required this.labelKey,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String labelKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? AppColors.surface
        : (isDarkTheme
            ? Colors.grey
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62));

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: AppSizes.spaceXs),
            CustomText(
              labelKey,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: AppSizes.fontLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
