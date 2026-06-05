import 'package:flutter/material.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class PortfolioAddPlaceholder extends StatelessWidget {
  const PortfolioAddPlaceholder({
    super.key,
    required this.currentCount,
    required this.maxCount,
    required this.scheme,
    required this.onTap,
  });

  final int currentCount;
  final int maxCount;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(
          color: AppColors.secondColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceSm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                ToukhIcons.image,
                size: 40,
                color: AppColors.secondColor,
              ),
              SizedBox(height: AppSizes.spaceSm),
              CustomText(
                AppStrings.Registration.portfolioAddPhoto,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppSizes.fontLabel,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.88),
                ),
              ),
              SizedBox(height: AppSizes.spaceXs),
              Text(
                '$currentCount/$maxCount',
                style: TextStyle(
                  fontSize: AppSizes.fontCaption,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
