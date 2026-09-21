import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/shared/maps/toukh_map_colors.dart';
import 'package:toukh_provider/shared/theme/app_colors.dart';

enum ToukhMapPinRole { pickup, destination, driver, brand }

Color _primaryForRole(ToukhMapPinRole role) {
  return switch (role) {
    ToukhMapPinRole.pickup => ToukhMapColors.pickup,
    ToukhMapPinRole.destination => ToukhMapColors.destination,
    ToukhMapPinRole.driver => ToukhMapColors.driver,
    ToukhMapPinRole.brand => AppColors.appColor,
  };
}

/// Builds a brand-styled map pin for reuse across Toukh apps.
Future<BitmapDescriptor> buildToukhMapPinDescriptor({
  ToukhMapPinRole role = ToukhMapPinRole.brand,
  Color? primary,
  Color ring = AppColors.surface,
  double logicalSize = 128,
}) async {
  final fillColor = primary ?? _primaryForRole(role);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = logicalSize;
  final center = Offset(s * 0.5, s * 0.36);
  final headR = s * 0.2;

  final fill = Paint()..color = fillColor;
  final stroke = Paint()
    ..color = ring
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.045;

  canvas.drawCircle(center, headR, fill);
  canvas.drawCircle(center, headR, stroke);

  final tipY = center.dy + headR * 2.15;
  final stem = Path()
    ..moveTo(center.dx, tipY)
    ..lineTo(center.dx - headR * 0.78, center.dy + headR * 0.42)
    ..lineTo(center.dx + headR * 0.78, center.dy + headR * 0.42)
    ..close();
  canvas.drawPath(stem, fill);
  canvas.drawPath(stem, stroke);

  final picture = recorder.endRecording();
  final image = await picture.toImage(s.toInt(), s.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  return BitmapDescriptor.bytes(bytes);
}
