import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class WelcomeLocaleChoiceCard extends StatelessWidget {
  const WelcomeLocaleChoiceCard({
    super.key,
    required this.selected,
    required this.flagText,
    required this.regionLabel,
    required this.languageLabel,
    required this.onTap,
  });

  final bool selected;
  final String flagText;
  final String regionLabel;
  final String languageLabel;
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
            horizontal: AppSizes.spaceMd,
            vertical: AppSizes.spaceBase,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    flagText,
                    style: const TextStyle(fontSize: 26, height: 1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageLabel,
                      style: TextStyle(
                        fontSize: AppSizes.fontTitle,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      PhosphorIconsFill.checkCircle,
                      size: 22,
                      color: AppColors.secondColor,
                    ),
                ],
              ),
              // SizedBox(height: AppSizes.spaceXs),
              // Text(
              //   languageLabel,
              //   style: TextStyle(
              //     fontSize: AppSizes.fontLabel,
              //     fontWeight: FontWeight.w500,
              //     color: scheme.onSurface.withValues(alpha: 0.62),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
