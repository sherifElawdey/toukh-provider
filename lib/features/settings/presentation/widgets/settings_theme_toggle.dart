import 'package:flutter/material.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_theme_mode_option.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

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
                child: SettingsThemeModeOption(
                  icon: Icons.light_mode_rounded,
                  labelKey: AppStrings.Common.light,
                  selected: !isDark,
                  onTap: () => onChanged(ThemeMode.light),
                ),
              ),
              Expanded(
                child: SettingsThemeModeOption(
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
