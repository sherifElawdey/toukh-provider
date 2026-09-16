import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Opens a near-fullscreen bottom sheet to view and pinch-zoom a network image.
Future<void> showNetworkImageZoomSheet(
  BuildContext context, {
  required String imageUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.black,
    showDragHandle: true,
    builder: (ctx) {
      final height = MediaQuery.sizeOf(ctx).height * 0.92;
      return SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: HavitNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                tooltip: AppStrings.Common.cancel.tr,
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Tappable thumbnail that opens [showNetworkImageZoomSheet].
class TappableNetworkImage extends StatelessWidget {
  const TappableNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final image = HavitNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
    );

    final child = borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: image)
        : image;

    return GestureDetector(
      onTap: () => showNetworkImageZoomSheet(context, imageUrl: imageUrl),
      child: child,
    );
  }
}
