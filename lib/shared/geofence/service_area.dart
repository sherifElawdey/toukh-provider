import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/shared/geofence/lat_lng_point.dart';
import 'package:toukh_provider/shared/orders/toukh_firestore_timestamps.dart';

/// Admin-defined polygon geofence used for address and provider matching.
class ServiceArea extends Equatable {
  const ServiceArea({
    required this.id,
    required this.name,
    required this.country,
    required this.governorate,
    required this.city,
    required this.enabled,
    required this.polygon,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String country;
  final String governorate;
  final String city;
  final bool enabled;
  final List<LatLngPoint> polygon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasValidPolygon => polygon.length >= 3;

  ServiceArea copyWith({
    String? id,
    String? name,
    String? country,
    String? governorate,
    String? city,
    bool? enabled,
    List<LatLngPoint>? polygon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceArea(
      id: id ?? this.id,
      name: name ?? this.name,
      country: country ?? this.country,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      enabled: enabled ?? this.enabled,
      polygon: polygon ?? this.polygon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore({bool includeServerTimestamps = true}) {
    return {
      'id': id,
      'name': name,
      'country': country,
      'governorate': governorate,
      'city': city,
      'enabled': enabled,
      'polygon': polygon.map((p) => p.toMap()).toList(),
      if (includeServerTimestamps) ...{
        if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
        if (createdAt != null)
          'createdAt': ToukhFirestoreTimestamps.fromDateTime(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      } else ...{
        if (createdAt != null)
          'createdAt': ToukhFirestoreTimestamps.fromDateTime(createdAt!),
        if (updatedAt != null)
          'updatedAt': ToukhFirestoreTimestamps.fromDateTime(updatedAt!),
      },
    };
  }

  factory ServiceArea.fromFirestore(String id, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final rawPolygon = map['polygon'];
    final points = <LatLngPoint>[];
    if (rawPolygon is List) {
      for (final item in rawPolygon) {
        if (item is Map) {
          points.add(LatLngPoint.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    return ServiceArea(
      id: id,
      name: (map['name'] as String?)?.trim() ?? '',
      country: (map['country'] as String?)?.trim() ?? '',
      governorate: (map['governorate'] as String?)?.trim() ?? '',
      city: (map['city'] as String?)?.trim() ?? '',
      enabled: map['enabled'] as bool? ?? true,
      polygon: points,
      createdAt: ToukhFirestoreTimestamps.toDateTime(map['createdAt']),
      updatedAt: ToukhFirestoreTimestamps.toDateTime(map['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        country,
        governorate,
        city,
        enabled,
        polygon,
        createdAt,
        updatedAt,
      ];
}
