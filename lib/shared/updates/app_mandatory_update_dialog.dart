import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/ui_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_text.dart';

/// Shows a non-dismissible mandatory update dialog with a store button.
Future<void> showAppMandatoryUpdateDialog(
  BuildContext context, {
  required String title,
  required String description,
  required Uri storeUri,
  required String updateButtonLabel,
  String imageAsset = ToukhUiAssets.brandingHavitIcon,
  String? imagePackage = kToukhUiPackageName,
  double imageWidth = 120,
  double imageHeight = 120,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          contentPadding: EdgeInsets.fromLTRB(
            AppSizes.spaceLg,
            AppSizes.spaceXl,
            AppSizes.spaceLg,
            AppSizes.spaceLg,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imageAsset,
                package: imagePackage,
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              SizedBox(height: AppSizes.spaceLg),
              CustomText(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondColor,
                    ),
              ),
              SizedBox(height: AppSizes.spaceSm),
              CustomText(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: Theme.of(dialogContext)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.75),
                    ),
              ),
              SizedBox(height: AppSizes.spaceXl),
              AppFilledButton(
                text: updateButtonLabel,
                width: double.infinity,
                onTap: () async {
                  if (await canLaunchUrl(storeUri)) {
                    await launchUrl(
                      storeUri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
