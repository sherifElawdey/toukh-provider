import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/ui_assets.dart';
import '../theme/app_colors.dart';

/// Full-bleed Havit splash Lottie that fills the viewport.
///
/// Renders the 1080×1920 composition through [FittedBox] + [BoxFit.cover] so
/// the Lottie center stays aligned to the screen center on any aspect ratio.
class HavitSplashView extends StatelessWidget {
  const HavitSplashView({
    super.key,
    this.backgroundColor,
  });

  final Color? backgroundColor;

  static const double _compWidth = 1080;
  static const double _compHeight = 1920;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.appColor;
    return ColoredBox(
      color: bg,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _compWidth,
            height: _compHeight,
            child: Lottie.asset(
              ToukhUiAssets.brandingHavitSplash,
              package: kToukhUiPackageName,
              fit: BoxFit.fill,
              alignment: Alignment.center,
              repeat: true,
              frameRate: FrameRate.max,
            ),
          ),
        ),
      ),
    );
  }
}
