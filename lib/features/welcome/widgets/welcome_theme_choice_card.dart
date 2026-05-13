import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class WelcomeThemeChoiceCard extends StatelessWidget {
  const WelcomeThemeChoiceCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? AppColors.secondColor
        : scheme.outline.withValues(alpha: 0.12);
    final fill = selected
        ? AppColors.secondColor.withValues(alpha: 0.08)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);

    return Material(
      color: fill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.spaceBase,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: selected
                    ? AppColors.secondColor
                    : scheme.onSurface.withValues(alpha: 0.55),
              ),
              SizedBox(height: AppSizes.spaceSm),
              CustomText(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontBody,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              if (selected) ...[
                SizedBox(height: 4),
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.secondColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
