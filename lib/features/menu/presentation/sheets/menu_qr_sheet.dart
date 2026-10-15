import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future<void> showMenuQrSheet(
  BuildContext context, {
  required String url,
  required String name,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Full screen width (Material 3 caps sheets at 640 by default).
    constraints: BoxConstraints(maxWidth: double.infinity,minWidth: MediaQuery.of(context).size.width),
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXl),
      ),
    ),
    builder: (ctx) => MenuQrSheet(url: url, name: name),
  );
}

class MenuQrSheet extends StatefulWidget {
  const MenuQrSheet({required this.url, required this.name, super.key});

  final String url;
  final String name;

  @override
  State<MenuQrSheet> createState() => _MenuQrSheetState();
}

class _MenuQrSheetState extends State<MenuQrSheet> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _menuQrCardPng(
        url: widget.url,
        name: widget.name,
        caption: AppStrings.Registration.menuQrHint.tr,
        textDirection: Directionality.of(context),
      );
      if (!mounted) return;
      if (bytes == null) {
        AppSnack.show(
          context,
          message: AppStrings.FirebaseErrors.tryAgain.tr,
          state: AppSnackState.error,
          icon: ToukhIcons.error,
        );
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 1, 1);
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: 'havit-menu-qr.png',
          ),
        ],
        text: widget.url,
        sharePositionOrigin: origin,
        fileNameOverrides: const ['havit-menu-qr.png'],
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: '$e',
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: AppSizes.spaceMd),
          CustomText(
            AppStrings.Registration.menuQr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          CustomText(
            AppStrings.Registration.menuQrHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spaceMd),
              child: QrImageView(
                data: widget.url,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          CustomText(
            widget.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.spaceLg),
          AppFilledButton(
            text: AppStrings.Registration.menuQrShare,
            icon: PhosphorIconsRegular.shareNetwork,
            status: _sharing
                ? AppButtonStatus.loading
                : AppButtonStatus.enabled,
            onTap: _share,
          ),
        ],
      ),
    );
  }
}

/// Shareable card: store name, QR and caption on white, sized for chats and
/// stories (4:5).
Future<Uint8List?> _menuQrCardPng({
  required String url,
  required String name,
  required String caption,
  required TextDirection textDirection,
}) async {
  const ink = Color(0xFF1A2B3C);
  const width = 1080.0;
  const height = 1350.0;
  const qrSize = 760.0;
  const qrTop = 300.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, 16),
    Paint()..color = AppColors.secondColor,
  );

  void drawText(
    String text, {
    required double top,
    required double fontSize,
    required FontWeight weight,
    required Color color,
    int maxLines = 2,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          height: 1.25,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: textDirection,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: width - 160);
    painter.paint(canvas, Offset((width - painter.width) / 2, top));
  }

  drawText(
    name.trim().isEmpty ? 'Hav-it' : name.trim(),
    top: 110,
    fontSize: 64,
    weight: FontWeight.w800,
    color: ink,
  );

  final painter = QrPainter(
    data: url,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
    gapless: true,
    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ink),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: ink,
    ),
  );
  canvas.save();
  canvas.translate((width - qrSize) / 2, qrTop);
  painter.paint(canvas, const Size(qrSize, qrSize));
  canvas.restore();

  drawText(
    caption,
    top: qrTop + qrSize + 60,
    fontSize: 40,
    weight: FontWeight.w600,
    color: ink.withValues(alpha: 0.75),
  );
  drawText(
    'Hav-it',
    top: height - 110,
    fontSize: 44,
    weight: FontWeight.w800,
    color: AppColors.secondColor,
    maxLines: 1,
  );

  final image = await recorder.endRecording().toImage(
    width.toInt(),
    height.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) return null;
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
