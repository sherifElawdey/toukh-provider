import 'package:flutter/material.dart';

import '../constants/ui_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import 'custom_text.dart';

/// Full-screen success state with optional illustration and primary action.
class AppSuccessScreen extends StatelessWidget {
  const AppSuccessScreen({
    super.key,
    required this.title,
    this.description,
    required this.actionText,
    required this.actionOnPressed,
    this.imagePath = ToukhUiAssets.brandingHavitIcon,
    this.imageAssetPackage = kToukhUiPackageName,
  });

  final String title;
  final String? description;
  final String actionText;
  final VoidCallback actionOnPressed;
  final String imagePath;

  /// When non-null, [Image.asset] loads from this package (host app assets use null).
  final String? imageAssetPackage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.thirdColor.withValues(alpha: 0.55),
              AppColors.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.space3xl,
              bottom: AppSizes.space2xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spaceMd),
                    child: imageAssetPackage != null
                        ? Image.asset(
                            imagePath,
                            package: imageAssetPackage,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(imagePath, fit: BoxFit.contain),
                  ),
                ),
                SizedBox(height: AppSizes.space2xl),
                CustomText(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontHeadline,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondColor,
                  ),
                ),
                if (description != null) ...[
                  SizedBox(height: AppSizes.spaceMd),
                  CustomText(
                    description!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppSizes.fontBody,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: actionOnPressed,
                  child: CustomText(actionText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
