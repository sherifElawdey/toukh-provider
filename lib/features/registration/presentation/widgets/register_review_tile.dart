import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterReviewTile extends StatelessWidget {
  const RegisterReviewTile({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.value,
    required this.scheme,
  });

  final IconData icon;
  final String titleKey;
  final String value;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  titleKey,
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
        ],
      ),
    );
  }
}
