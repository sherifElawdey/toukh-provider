import 'package:flutter/material.dart';
import 'package:toukh_provider/shared/icons/toukh_icons.dart';
import 'package:toukh_provider/shared/theme/app_colors.dart';
import 'package:toukh_provider/shared/theme/app_sizes.dart';
import 'package:toukh_provider/shared/widgets/app_button.dart';
import 'package:toukh_provider/shared/widgets/custom_text.dart';

/// In-feature CTA when location is needed but not granted.
///
/// Pass [permanentlyDenied] when the OS will not show the system dialog again
/// so the button opens Settings instead of requesting again.
class LocationPermissionTile extends StatelessWidget {
  const LocationPermissionTile({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.busy = false,
    this.compact = false,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool busy;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSizes.spaceMd : AppSizes.spaceBase),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              ToukhIcons.location,
              size: AppSizes.iconLg,
              color: AppColors.secondColor,
            ),
            SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    title,
                    style: TextStyle(
                      fontSize: compact ? AppSizes.fontBody : AppSizes.fontTitle,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceXs),
                  CustomText(
                    message,
                    style: TextStyle(
                      fontSize: AppSizes.fontCaption,
                      height: 1.35,
                      color: scheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSizes.spaceSm),
            AppOutlinedButton(
              text: actionLabel,
              size: AppButtonSize.small,
              status: busy || onAction == null
                  ? AppButtonStatus.disabled
                  : AppButtonStatus.enabled,
              onTap: onAction,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd,
                vertical: AppSizes.spaceSm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
