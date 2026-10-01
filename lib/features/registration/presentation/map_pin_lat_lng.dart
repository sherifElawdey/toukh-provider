import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Geographic point under the bottom-center of [pinKey] (the pin tip).
///
/// [GoogleMapController.getLatLng] is relative to the map's top-left.
/// Android's projection uses physical pixels, so [devicePixelRatio] is applied
/// there. iOS uses view points, which match Flutter logical pixels.
Future<LatLng?> latLngAtPinTip({
  required GoogleMapController? controller,
  required GlobalKey pinKey,
  required GlobalKey mapKey,
  required double devicePixelRatio,
}) async {
  final map = controller;
  if (map == null) return null;
  final pinBox = pinKey.currentContext?.findRenderObject() as RenderBox?;
  final mapBox = mapKey.currentContext?.findRenderObject() as RenderBox?;
  if (pinBox == null || !pinBox.hasSize || mapBox == null || !mapBox.hasSize) {
    return null;
  }
  final tipGlobal = pinBox.localToGlobal(
    Offset(pinBox.size.width / 2, pinBox.size.height),
  );
  final tipInMap = mapBox.globalToLocal(tipGlobal);
  final scale = switch (defaultTargetPlatform) {
    TargetPlatform.android => devicePixelRatio,
    _ => 1.0,
  };
  return map.getLatLng(
    ScreenCoordinate(
      x: (tipInMap.dx * scale).round(),
      y: (tipInMap.dy * scale).round(),
    ),
  );
}
