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
  });

  final IconData icon;
  final String titleKey;
  final String value;
  final ColorScheme scheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceMd),
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
              ],
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: AppSizes.spaceSm),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ],
      ),
    );

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
