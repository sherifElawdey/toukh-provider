import 'package:flutter/material.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class PermissionItemCard extends StatelessWidget {
  const PermissionItemCard({
    super.key,
    required this.granted,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.busy,
    required this.onEnable,
  });

  final bool granted;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool busy;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fillColor = granted ? AppColors.success.withValues(alpha: 0.1) : null;

    return Material(
      color: fillColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceBase,
          vertical: AppSizes.spaceMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              granted ? Icons.check_circle_rounded : icon,
              size: AppSizes.iconLg + 4,
              color: granted ? AppColors.success : AppColors.secondColor,
            ),
            SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    style: TextStyle(
                      fontSize: AppSizes.fontTitle,
                      fontWeight: FontWeight.w600,
                      color: granted ? AppColors.success : scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceXs),
                  CustomText(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppSizes.fontLabel,
                      height: 1.35,
                      color: scheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSizes.spaceSm),
            if (!granted)
              OutlinedButton(
                onPressed: busy ? null : onEnable,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceMd,
                    vertical: AppSizes.spaceSm,
                  ),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
                child: CustomText(AppStrings.Permissions.enable),
              )
            else
              CustomText(
                AppStrings.Permissions.allowed,
                style: TextStyle(
                  fontSize: AppSizes.fontLabel,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
