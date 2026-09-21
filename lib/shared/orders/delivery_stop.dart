import 'package:equatable/equatable.dart';

import '../models/location.dart';
import 'provider_sub_state.dart';
import 'toukh_firestore_timestamps.dart';

class DeliveryStop extends Equatable {
  const DeliveryStop({
    required this.providerId,
    required this.providerOrderId,
    required this.location,
    this.providerName,
    this.state = ProviderSubState.accepted,
    this.sequence = 0,
    this.pickupVerifiedAt,
  });

  final String providerId;
  final String providerOrderId;
  final Location location;
  final String? providerName;
  final ProviderSubState state;
  final int sequence;
  final DateTime? pickupVerifiedAt;

  bool get isPickedUp => state == ProviderSubState.pickedUp;

  DeliveryStop copyWith({
    ProviderSubState? state,
    DateTime? pickupVerifiedAt,
  }) {
    return DeliveryStop(
      providerId: providerId,
      providerOrderId: providerOrderId,
      location: location,
      providerName: providerName,
      state: state ?? this.state,
      sequence: sequence,
      pickupVerifiedAt: pickupVerifiedAt ?? this.pickupVerifiedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'providerOrderId': providerOrderId,
        'location': location.toMap(),
        if (providerName != null) 'providerName': providerName,
        'state': state.wireValue,
        'sequence': sequence,
        if (pickupVerifiedAt != null)
          'pickupVerifiedAt':
              ToukhFirestoreTimestamps.fieldFromDateTime(pickupVerifiedAt),
      };

  factory DeliveryStop.fromMap(Map<String, dynamic> map) {
    return DeliveryStop(
      providerId: map['providerId'] as String? ?? '',
      providerOrderId: map['providerOrderId'] as String? ?? '',
      location: Location.fromMap(
        Map<String, dynamic>.from(map['location'] as Map? ?? {}),
      ),
      providerName: map['providerName'] as String?,
      state: ProviderSubState.fromWire(map['state'] as String?),
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
      pickupVerifiedAt: _parseDate(map['pickupVerifiedAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  @override
  List<Object?> get props =>
      [providerId, providerOrderId, location, providerName, state, sequence, pickupVerifiedAt];
}
