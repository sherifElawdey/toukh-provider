import 'package:equatable/equatable.dart';

import '../models/location.dart';
import 'delivery_route_quote.dart';
import 'delivery_stop.dart';
import 'delivery_task_status.dart';
import 'driver_assignment.dart';
import 'toukh_firestore_timestamps.dart';

class DeliveryTask extends Equatable {
  const DeliveryTask({
    required this.id,
    required this.masterOrderId,
    required this.status,
    this.driverAssignment,
    this.stops = const [],
    this.deliveryLocation,
    this.allProvidersResponded = false,
    this.route,
    this.deliveryFeeEgp = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String masterOrderId;
  final DeliveryTaskStatus status;
  final DriverAssignment? driverAssignment;
  final List<DeliveryStop> stops;
  final Location? deliveryLocation;
  final bool allProvidersResponded;
  final DeliveryRouteSnapshot? route;
  final double deliveryFeeEgp;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get allStopsPicked =>
      stops.isNotEmpty && stops.every((s) => s.isPickedUp);

  int get pickedStopCount => stops.where((s) => s.isPickedUp).length;

  List<DeliveryStop> get stopsInSequence {
    final sorted = [...stops]..sort((a, b) => a.sequence.compareTo(b.sequence));
    return sorted;
  }

  DeliveryStop? get nextPendingStop {
    for (final s in stopsInSequence) {
      if (!s.isPickedUp) return s;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'masterOrderId': masterOrderId,
        'status': status.wireValue,
        if (driverAssignment != null)
          'driverAssignment': driverAssignment!.toMap(),
        'stops': stops.map((s) => s.toMap()).toList(),
        if (deliveryLocation != null)
          'deliveryLocation': deliveryLocation!.toMap(),
        'allProvidersResponded': allProvidersResponded,
        if (route != null) 'route': route!.toMap(),
        'deliveryFeeEgp': deliveryFeeEgp,
        if (createdAt != null)
          'createdAt': ToukhFirestoreTimestamps.fieldFromDateTime(createdAt),
        if (updatedAt != null)
          'updatedAt': ToukhFirestoreTimestamps.fieldFromDateTime(updatedAt),
      };

  factory DeliveryTask.fromMap(String id, Map<String, dynamic> map) {
    final stopsRaw = map['stops'];
    final stops = stopsRaw is List
        ? stopsRaw
            .map(
              (e) =>
                  DeliveryStop.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList()
        : <DeliveryStop>[];

    return DeliveryTask(
      id: id,
      masterOrderId: map['masterOrderId'] as String? ?? '',
      status: DeliveryTaskStatus.fromWire(map['status'] as String?),
      driverAssignment: map['driverAssignment'] != null
          ? DriverAssignment.fromMap(
              Map<String, dynamic>.from(map['driverAssignment'] as Map),
            )
          : null,
      stops: stops,
      deliveryLocation: map['deliveryLocation'] != null
          ? Location.fromMap(
              Map<String, dynamic>.from(map['deliveryLocation'] as Map),
            )
          : null,
      allProvidersResponded: map['allProvidersResponded'] as bool? ?? false,
      route: map['route'] is Map
          ? DeliveryRouteSnapshot.fromMap(
              Map<String, dynamic>.from(map['route'] as Map),
            )
          : null,
      deliveryFeeEgp: (map['deliveryFeeEgp'] as num?)?.toDouble() ??
          (map['route'] is Map
              ? ((map['route'] as Map)['deliveryFee'] as num?)?.toDouble() ?? 0
              : 0),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  @override
  List<Object?> get props => [
        id,
        masterOrderId,
        status,
        driverAssignment,
        stops,
        deliveryLocation,
        allProvidersResponded,
        route,
        deliveryFeeEgp,
        createdAt,
        updatedAt,
      ];
}
