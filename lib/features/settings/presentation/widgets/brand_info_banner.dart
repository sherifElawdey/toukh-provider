import 'package:flutter/material.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Prompt shown on Settings until the provider saves brand contacts.
class BrandInfoBanner extends StatelessWidget {
  const BrandInfoBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: AppColors.secondColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: scheme.onSurface.withValues(alpha: 0.32),
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceBase,
            vertical: AppSizes.spaceMd,
          ),
          child: Row(
            children: [
              Icon(
                ToukhIcons.store,
                color: AppColors.secondColor,
                size: AppSizes.iconLg,
              ),
              SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.Settings.brandInfoBannerTitle,
                      style: TextStyle(
                        fontSize: AppSizes.fontBody,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      AppStrings.Settings.brandInfoBannerBody,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: AppSizes.fontLabel,
                        height: 1.35,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSizes.spaceSm),
              Icon(
                ToukhIcons.chevronRight,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
