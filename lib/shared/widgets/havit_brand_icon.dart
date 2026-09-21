import 'package:flutter/material.dart';

import '../constants/ui_assets.dart';

/// Shared Havit square brand mark for auth, welcome, status, and in-app slots.
///
/// Uses PNG because [havit_icon.svg] is an SVG shell around an embedded raster
/// image, which flutter_svg cannot paint.
class HavitBrandIcon extends StatelessWidget {
  const HavitBrandIcon({
    super.key,
    this.size = 88,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  final double size;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      ToukhUiAssets.brandingHavitIcon,
      package: kToukhUiPackageName,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }
    return image;
  }
}
