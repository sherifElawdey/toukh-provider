import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:toukh_provider/shared/constants/ui_assets.dart';
import 'package:toukh_provider/shared/widgets/toukh_section_placeholder.dart';

/// Lottie animation for a [ToukhServiceCategory] section tile or empty state.
class ToukhServiceLottie extends StatelessWidget {
  const ToukhServiceLottie({
    super.key,
    required this.category,
    this.loop,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final ToukhServiceCategory category;
  final bool? loop;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final shouldLoop = loop ?? category.defaultLoop;

    return Lottie.asset(
      category.lottieAsset,
      package: kToukhUiPackageName,
      width: width,
      height: height,
      fit: fit,
      repeat: shouldLoop,
      errorBuilder: (context, error, stackTrace) {
        if (!category.hasPlaceholder) {
          return SizedBox(width: width, height: height);
        }
        return ToukhSectionPlaceholder(
          category: category,
          width: width ?? 72,
          height: height ?? 72,
          fit: fit,
        );
      },
    );
  }
}
