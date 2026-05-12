import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Card-style row (matches consumer profile settings tiles).
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.titleKey,
    this.trailing,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String titleKey;
  final Widget? trailing;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.appColor;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceSm),
      elevation: 0,
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      //   side: BorderSide(color: AppColors.borderSubtle),
      // ),
      child: Material(
        // color: scheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceBase,
              vertical: AppSizes.spaceMd,
            ),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 24),
                SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: CustomText(
                    titleKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontBody,
                    ),
                  ),
                ),
                ...[?trailing],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
