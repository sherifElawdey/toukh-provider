import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:toukh_provider/shared/constants/ui_assets.dart';

/// Section-specific empty-state illustration from [ToukhServiceCategory].
class ToukhSectionPlaceholder extends StatelessWidget {
  const ToukhSectionPlaceholder({
    super.key,
    required this.category,
    this.width = 120,
    this.height = 120,
    this.fit = BoxFit.contain,
  });

  final ToukhServiceCategory category;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final asset = category.placeholderAsset;
    if (asset == null) {
      return Lottie.asset(
        category.lottieAsset,
        package: kToukhUiPackageName,
        width: width,
        height: height,
        fit: fit,
        repeat: false,
      );
    }

    return SvgPicture.asset(
      asset,
      package: kToukhUiPackageName,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
