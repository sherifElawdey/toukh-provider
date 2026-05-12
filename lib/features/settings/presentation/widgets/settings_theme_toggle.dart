import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

/// Pill light/dark toggle (consumer app settings pattern).
class SettingsThemeToggle extends StatelessWidget {
  const SettingsThemeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = value == ThemeMode.dark;
    final scheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final highlightAlignment = isDark
        ? (isRtl ? Alignment.centerLeft : Alignment.centerRight)
        : (isRtl ? Alignment.centerRight : Alignment.centerLeft);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: highlightAlignment,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? scheme.onSurface : AppColors.appColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ThemeModeOption(
                  icon: Icons.light_mode_rounded,
                  labelKey: AppStrings.Common.light,
                  selected: !isDark,
                  onTap: () => onChanged(ThemeMode.light),
                ),
              ),
              Expanded(
                child: _ThemeModeOption(
                  icon: Icons.dark_mode_rounded,
                  labelKey: AppStrings.Common.dark,
                  selected: isDark,
                  onTap: () => onChanged(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
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
