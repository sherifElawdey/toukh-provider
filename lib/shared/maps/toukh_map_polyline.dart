import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/shared/maps/toukh_map_colors.dart';

/// Shared route polyline styling for Toukh maps.
abstract final class ToukhMapPolyline {
  static Polyline build({
    required String id,
    required List<LatLng> points,
    double width = 4.5,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      points: points,
      color: ToukhMapColors.polyline,
      width: width.toInt(),
      geodesic: true,
    );
  }
}
