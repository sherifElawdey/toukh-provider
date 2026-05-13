import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class LanguageSelectionOption extends StatelessWidget {
  const LanguageSelectionOption({
    super.key,
    required this.flag,
    required this.labelKey,
    required this.locale,
    required this.selected,
    required this.onSelected,
  });

  final String flag;
  final String labelKey;
  final Locale locale;
  final bool selected;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
      child: Material(
        color: selected
            ? AppColors.secondColor.withValues(alpha: 0.1)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: () => onSelected(locale),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceBase,
              vertical: AppSizes.spaceMd,
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 28)),
                SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: CustomText(
                    labelKey,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontBody,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.secondColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
