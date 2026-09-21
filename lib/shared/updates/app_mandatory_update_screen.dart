import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../icons/toukh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../widgets/app_button.dart';
import '../widgets/custom_text.dart';
import 'toukh_remote_config_keys.dart';
import 'toukh_store_listings.dart';

/// Full-screen mandatory update prompt with store button.
///
/// Android system back cannot leave this screen ([PopScope.canPop] is false).
/// The user can open the store or leave via system Home / Recents.
class AppMandatoryUpdateScreen extends StatelessWidget {
  const AppMandatoryUpdateScreen({
    super.key,
    required this.title,
    required this.description,
    required this.updateButtonLabel,
    this.storeUri,
    this.remoteConfigKey,
    this.imageAsset,
    this.imagePackage,
    this.imageWidth = 160,
    this.imageHeight = 160,
  });

  final String title;
  final String description;
  final String updateButtonLabel;

  /// Store listing to open. If null, resolved from [remoteConfigKey].
  final Uri? storeUri;

  /// Remote Config key used to resolve a store URI when [storeUri] is missing.
  final String? remoteConfigKey;

  /// Optional branding image. When null, an update icon is shown instead.
  final String? imageAsset;
  final String? imagePackage;
  final double imageWidth;
  final double imageHeight;

  Uri? get _resolvedStoreUri {
    if (storeUri != null) return storeUri;
    final key = remoteConfigKey;
    if (key != null && ToukhRemoteConfigKeys.all.contains(key)) {
      return ToukhStoreListings.resolveStoreUriForRemoteConfigKey(key);
    }
    return null;
  }

  Future<void> _openStore() async {
    final uri = _resolvedStoreUri;
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.thirdColor.withValues(alpha: 0.65),
                AppColors.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: AppSizes.screenPadding,
              child: Column(
                children: [
                  const Spacer(),
                  if (imageAsset != null)
                    Image.asset(
                      imageAsset!,
                      package: imagePackage,
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    )
                  else
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.thirdColor.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ToukhIcons.arrowCircleUp,
                        size: 48,
                        color: AppColors.secondColor,
                      ),
                    ),
                  SizedBox(height: AppSizes.space2xl),
                  CustomText(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondColor,
                        ),
                  ),
                  SizedBox(height: AppSizes.spaceMd),
                  CustomText(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.45,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.75),
                        ),
                  ),
                  const Spacer(),
                  AppFilledButton(
                    text: updateButtonLabel,
                    width: double.infinity,
                    onTap: _openStore,
                  ),
                  SizedBox(height: AppSizes.spaceMd),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
