import 'package:equatable/equatable.dart';

/// One restaurant stop in an optimized delivery route.
class OptimizedRestaurantStop extends Equatable {
  const OptimizedRestaurantStop({
    required this.providerId,
    required this.sequence,
    required this.lat,
    required this.lng,
    this.name,
  });

  final String providerId;
  final int sequence;
  final double lat;
  final double lng;
  final String? name;

  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'sequence': sequence,
        'lat': lat,
        'lng': lng,
        if (name != null) 'name': name,
      };

  factory OptimizedRestaurantStop.fromMap(Map<String, dynamic> map) {
    return OptimizedRestaurantStop(
      providerId: map['providerId'] as String? ?? '',
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
      name: map['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [providerId, sequence, lat, lng, name];
}

/// Live checkout quote from [calculateDeliveryRoute] callable.
class DeliveryRouteQuote extends Equatable {
  const DeliveryRouteQuote({
    required this.quoteId,
    required this.optimizedRestaurants,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.pricePerKm,
    required this.deliveryFee,
    this.encodedPolyline,
    this.billableDistanceMeters = 0,
    this.billableDistanceKm = 0,
    this.appliedMultiplier = 1,
    this.freeByThreshold = false,
    this.settingsVersion = 1,
    this.calculatedAt,
    this.fromCache = false,
  });

  final String quoteId;
  final List<OptimizedRestaurantStop> optimizedRestaurants;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final double pricePerKm;
  final double deliveryFee;
  final String? encodedPolyline;
  final int billableDistanceMeters;
  final double billableDistanceKm;
  final double appliedMultiplier;
  final bool freeByThreshold;
  final int settingsVersion;
  final DateTime? calculatedAt;
  final bool fromCache;

  double get totalDistanceKm => totalDistanceMeters / 1000.0;

  Duration get totalDuration => Duration(seconds: totalDurationSeconds);

  factory DeliveryRouteQuote.fromMap(Map<String, dynamic> map) {
    final stopsRaw = map['optimizedRestaurants'];
    final stops = stopsRaw is List
        ? stopsRaw
            .whereType<Map>()
            .map((e) => OptimizedRestaurantStop.fromMap(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <OptimizedRestaurantStop>[];

    DateTime? calculatedAt;
    final rawAt = map['calculatedAt'];
    if (rawAt is String) {
      calculatedAt = DateTime.tryParse(rawAt);
    }

    return DeliveryRouteQuote(
      quoteId: map['quoteId'] as String? ?? '',
      optimizedRestaurants: stops,
      totalDistanceMeters: (map['totalDistanceMeters'] as num?)?.toInt() ?? 0,
      totalDurationSeconds: (map['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      pricePerKm: (map['pricePerKm'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      encodedPolyline: map['encodedPolyline'] as String?,
      billableDistanceMeters:
          (map['billableDistanceMeters'] as num?)?.toInt() ?? 0,
      billableDistanceKm: (map['billableDistanceKm'] as num?)?.toDouble() ?? 0,
      appliedMultiplier: (map['appliedMultiplier'] as num?)?.toDouble() ?? 1,
      freeByThreshold: map['freeByThreshold'] as bool? ?? false,
      settingsVersion: (map['settingsVersion'] as num?)?.toInt() ?? 1,
      calculatedAt: calculatedAt,
      fromCache: map['fromCache'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'quoteId': quoteId,
        'optimizedRestaurants':
            optimizedRestaurants.map((e) => e.toMap()).toList(),
        'totalDistanceMeters': totalDistanceMeters,
        'totalDurationSeconds': totalDurationSeconds,
        'pricePerKm': pricePerKm,
        'deliveryFee': deliveryFee,
        if (encodedPolyline != null) 'encodedPolyline': encodedPolyline,
        'billableDistanceMeters': billableDistanceMeters,
        'billableDistanceKm': billableDistanceKm,
        'appliedMultiplier': appliedMultiplier,
        'freeByThreshold': freeByThreshold,
        'settingsVersion': settingsVersion,
        if (calculatedAt != null)
          'calculatedAt': calculatedAt!.toIso8601String(),
        'fromCache': fromCache,
      };

  /// Frozen snapshot stored on master orders / delivery tasks.
  DeliveryRouteSnapshot toSnapshot() => DeliveryRouteSnapshot(
        quoteId: quoteId,
        optimizedRestaurants: optimizedRestaurants,
        totalDistanceMeters: totalDistanceMeters,
        totalDurationSeconds: totalDurationSeconds,
        pricePerKm: pricePerKm,
        deliveryFee: deliveryFee,
        encodedPolyline: encodedPolyline,
        billableDistanceMeters: billableDistanceMeters,
        billableDistanceKm: billableDistanceKm,
        appliedMultiplier: appliedMultiplier,
        calculatedAt: calculatedAt,
      );

  @override
  List<Object?> get props => [
        quoteId,
        optimizedRestaurants,
        totalDistanceMeters,
        totalDurationSeconds,
        pricePerKm,
        deliveryFee,
        encodedPolyline,
      ];
}

/// Immutable route + fee frozen at order placement. Never recalculated.
class DeliveryRouteSnapshot extends Equatable {
  const DeliveryRouteSnapshot({
    this.quoteId,
    this.optimizedRestaurants = const [],
    this.totalDistanceMeters = 0,
    this.totalDurationSeconds = 0,
    this.pricePerKm = 0,
    this.deliveryFee = 0,
    this.encodedPolyline,
    this.billableDistanceMeters = 0,
    this.billableDistanceKm = 0,
    this.appliedMultiplier = 1,
    this.calculatedAt,
  });

  final String? quoteId;
  final List<OptimizedRestaurantStop> optimizedRestaurants;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final double pricePerKm;
  final double deliveryFee;
  final String? encodedPolyline;
  final int billableDistanceMeters;
  final double billableDistanceKm;
  final double appliedMultiplier;
  final DateTime? calculatedAt;

  double get totalDistanceKm => totalDistanceMeters / 1000.0;

  Map<String, dynamic> toMap() => {
        if (quoteId != null) 'quoteId': quoteId,
        'optimizedRestaurants':
            optimizedRestaurants.map((e) => e.toMap()).toList(),
        'totalDistanceMeters': totalDistanceMeters,
        'totalDurationSeconds': totalDurationSeconds,
        'pricePerKm': pricePerKm,
        'deliveryFee': deliveryFee,
        if (encodedPolyline != null) 'encodedPolyline': encodedPolyline,
        'billableDistanceMeters': billableDistanceMeters,
        'billableDistanceKm': billableDistanceKm,
        'appliedMultiplier': appliedMultiplier,
        if (calculatedAt != null)
          'calculatedAt': calculatedAt!.toIso8601String(),
      };

  factory DeliveryRouteSnapshot.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const DeliveryRouteSnapshot();
    }
    final stopsRaw = map['optimizedRestaurants'];
    final stops = stopsRaw is List
        ? stopsRaw
            .whereType<Map>()
            .map((e) => OptimizedRestaurantStop.fromMap(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <OptimizedRestaurantStop>[];

    DateTime? calculatedAt;
    final rawAt = map['calculatedAt'];
    if (rawAt is String) {
      calculatedAt = DateTime.tryParse(rawAt);
    }

    return DeliveryRouteSnapshot(
      quoteId: map['quoteId'] as String?,
      optimizedRestaurants: stops,
      totalDistanceMeters: (map['totalDistanceMeters'] as num?)?.toInt() ?? 0,
      totalDurationSeconds: (map['totalDurationSeconds'] as num?)?.toInt() ?? 0,
      pricePerKm: (map['pricePerKm'] as num?)?.toDouble() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      encodedPolyline: map['encodedPolyline'] as String?,
      billableDistanceMeters:
          (map['billableDistanceMeters'] as num?)?.toInt() ?? 0,
      billableDistanceKm: (map['billableDistanceKm'] as num?)?.toDouble() ?? 0,
      appliedMultiplier: (map['appliedMultiplier'] as num?)?.toDouble() ?? 1,
      calculatedAt: calculatedAt,
    );
  }

  @override
  List<Object?> get props => [
        quoteId,
        optimizedRestaurants,
        totalDistanceMeters,
        totalDurationSeconds,
        pricePerKm,
        deliveryFee,
      ];
}
