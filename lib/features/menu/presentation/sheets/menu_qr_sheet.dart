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
      final bytes = await _menuQrPng(widget.url);
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

Future<Uint8List?> _menuQrPng(String url) async {
  final painter = QrPainter(
    data: url,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.M,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Color(0xFF1A2B3C),
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Color(0xFF1A2B3C),
    ),
  );
  const size = 800.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  painter.paint(canvas, const Size(size, size));
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) return null;
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
