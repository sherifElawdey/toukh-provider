import 'package:flutter/material.dart';

import '../constants/ui_assets.dart';
import '../theme/app_colors.dart';

/// Circular person avatar with shared profile placeholder when [imageUrl] is empty/fails.
class ToukhProfileAvatar extends StatelessWidget {
  const ToukhProfileAvatar({
    super.key,
    this.imageUrl,
    this.size = 56,
    this.backgroundColor,
  });

  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final bg = backgroundColor ??
        AppColors.appColor.withValues(alpha: 0.12);

    return ClipOval(
      child: ColoredBox(
        color: bg,
        child: SizedBox(
          width: size,
          height: size,
          child: url.isEmpty
              ? _placeholder()
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => _placeholder(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _placeholder();
                  },
                ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Padding(
      padding: EdgeInsets.all(size * 0.18),
      child: Image.asset(
        ToukhUiAssets.placeholderProfileAvatar,
        package: kToukhUiPackageName,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
