import 'package:flutter/material.dart';

import '../icons/toukh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// Compact sun/moon icon toggle for settings theme rows.
class ToukhThemeModeIconToggle extends StatelessWidget {
  const ToukhThemeModeIconToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  static const _width = 76.0;
  static const _height = 32.0;
  static const _segmentSize = 36.0;

  @override
  Widget build(BuildContext context) {
    final isDark = value == ThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final highlightAlignment = isDark
        ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
        : (isRtl ? Alignment.centerRight : Alignment.centerLeft);

    final mutedIcon = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade400
        : scheme.onSurface.withValues(alpha: 0.55);

    return SizedBox(
      width: _width,
      height: _height,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: highlightAlignment,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: Container(
                width: _segmentSize,
                height: _height - 4,
                decoration: BoxDecoration(
                  color: isDark ? scheme.onSurface : AppColors.appColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _IconTarget(
                    icon: ToukhIcons.lightMode,
                    selected: !isDark,
                    selectedColor: AppColors.surface,
                    unselectedColor: mutedIcon,
                    onTap: () => onChanged(ThemeMode.light),
                  ),
                ),
                Expanded(
                  child: _IconTarget(
                    icon: ToukhIcons.darkMode,
                    selected: isDark,
                    selectedColor: AppColors.surface,
                    unselectedColor: mutedIcon,
                    onTap: () => onChanged(ThemeMode.dark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTarget extends StatelessWidget {
  const _IconTarget({
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: selected ? selectedColor : unselectedColor,
          ),
        ),
      ),
    );
  }
}
