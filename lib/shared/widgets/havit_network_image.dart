import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'havit_brand_icon.dart';

/// Network image with a branded Havit placeholder for loading, error, and empty URL.
///
/// Uses [Image.network] (no disk cache) so Android does not need JNI-backed
/// path_provider from flutter_cache_manager.
class HavitNetworkImage extends StatelessWidget {
  const HavitNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.high,
  });

  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;

  static const double _brandPlaceholderSize = 28;
  static const double _compactBrandSize = 20;
  static const double _placeholderBgAlpha = 0.2;

  Widget _placeholder({required bool compact}) {
    return ColoredBox(
      color: AppColors.appColor.withValues(alpha: _placeholderBgAlpha),
      child: Center(
        child: HavitBrandIcon(
          size: compact ? _compactBrandSize : _brandPlaceholderSize,
        ),
      ),
    );
  }

  bool _isCompact(BoxConstraints constraints) {
    final h = constraints.maxHeight;
    return h.isFinite && h > 0 && h < 72;
  }

  Widget _sizedPlaceholder({required bool compact}) {
    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _placeholder(compact: compact || _isCompact(constraints)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _sizedPlaceholder(compact: false);
    }

    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      filterQuality: filterQuality,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _sizedPlaceholder(compact: false);
      },
      errorBuilder: (context, error, stackTrace) =>
          _sizedPlaceholder(compact: false),
    );
  }
}
