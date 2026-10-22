import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterReviewTile extends StatelessWidget {
  const RegisterReviewTile({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.value,
    required this.scheme,
    this.onTap,
    this.errorText,
  });

  final IconData icon;
  final String titleKey;
  final String value;
  final ColorScheme scheme;
  final VoidCallback? onTap;

  /// Shown under the value with an error outline when this row needs fixing.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    final hasError = error != null;
    final row = Padding(
      padding: hasError
          ? const EdgeInsets.all(AppSizes.spaceSm)
          : const EdgeInsets.only(bottom: AppSizes.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                scheme.surfaceContainerHighest.withValues(alpha: 0.9),
            child: Icon(icon, color: AppColors.secondColor, size: 22),
          ),
          SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  titleKey.tr,
                  style: TextStyle(
                    fontSize: AppSizes.fontLabel,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
                SizedBox(height: AppSizes.spaceXs),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.fontBody,
                    height: 1.35,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasError) ...[
                  SizedBox(height: AppSizes.spaceXs),
                  Text(
                    error,
                    style: TextStyle(
                      fontSize: AppSizes.fontLabel,
                      height: 1.35,
                      color: scheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: AppSizes.spaceSm),
            Icon(
              ToukhIcons.chevronRight,
              color: hasError
                  ? scheme.error
                  : scheme.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ],
      ),
    );

    final content = hasError
        ? Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spaceMd),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.35),
                border: Border.all(color: scheme.error),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: row,
            ),
          )
        : row;

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: content,
      ),
    );
  }
}
