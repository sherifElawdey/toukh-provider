import 'package:flutter/material.dart';

import '../constants/ui_assets.dart';

/// Full Havit wordmark for shell app bars.
///
/// Loads the PNG cropped from [havit_logo.svg] (that file embeds a raster;
/// flutter_svg cannot paint it). Aspect is the wide logo (~457×202).
class HavitAppBarLogo extends StatelessWidget {
  const HavitAppBarLogo({
    super.key,
    this.height = 32,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    // Preserve wide logo aspect (~2.26:1) without overflowing the AppBar title.
    final width = height * (457 / 202);
    return Image.asset(
      ToukhUiAssets.brandingHavitLogo,
      package: kToukhUiPackageName,
      height: height,
      width: width,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.high,
    );
  }
}
