import 'package:equatable/equatable.dart';

/// Simple latitude/longitude pair for polygon vertices (Firestore-friendly).
class LatLngPoint extends Equatable {
  const LatLngPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  Map<String, dynamic> toMap() => {'lat': lat, 'lng': lng};

  factory LatLngPoint.fromMap(Map<String, dynamic> map) {
    return LatLngPoint(
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [lat, lng];
}
