import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/ui_assets.dart';
import '../theme/app_sizes.dart';

/// Looping Havit Lottie used by [AppLoadingMark] / [withAppLoading].
class AppLogoLoading extends StatelessWidget {
  const AppLogoLoading({super.key, this.size = AppSizes.logoLoading});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          ToukhUiAssets.loaderHavit,
          package: kToukhUiPackageName,
          fit: BoxFit.contain,
          repeat: true,
          frameRate: FrameRate.max,
        ),
      ),
    );
  }
}
