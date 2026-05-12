import 'package:flutter/material.dart';
import 'package:toukh_provider/core/constants/app_assets.dart';

/// Toukh Service wordmark-free mark (provider artwork).
class ToukhServiceLogo extends StatelessWidget {
  const ToukhServiceLogo({
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
      AppAssets.brandingProviderAppIcon,
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
