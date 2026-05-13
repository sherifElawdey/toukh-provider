import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class BlockedInfoCard extends StatelessWidget {
  const BlockedInfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.showLabelOnly = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool showLabelOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.thirdColor.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceBase,
          vertical: AppSizes.spaceMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSizes.iconLg, color: AppColors.secondColor),
            SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    label,
                    style: TextStyle(
                      fontSize: showLabelOnly
                          ? AppSizes.fontBody
                          : AppSizes.fontLabel,
                      fontWeight: showLabelOnly
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: showLabelOnly
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (!showLabelOnly && value.isNotEmpty) ...[
                    SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      value,
                      style: TextStyle(
                        fontSize: AppSizes.fontBody,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
