import 'package:equatable/equatable.dart';

import 'toukh_firestore_timestamps.dart';

class OrderTimelineEvent extends Equatable {
  const OrderTimelineEvent({
    required this.id,
    required this.masterOrderId,
    required this.type,
    required this.at,
    this.actorRole,
    this.actorId,
    this.payload = const {},
  });

  final String id;
  final String masterOrderId;
  final String type;
  final DateTime at;
  final String? actorRole;
  final String? actorId;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toMap() => {
        'masterOrderId': masterOrderId,
        'type': type,
        'at': ToukhFirestoreTimestamps.fromDateTime(at),
        if (actorRole != null) 'actorRole': actorRole,
        if (actorId != null) 'actorId': actorId,
        'payload': payload,
      };

  factory OrderTimelineEvent.fromMap(String id, Map<String, dynamic> map) {
    return OrderTimelineEvent(
      id: id,
      masterOrderId: map['masterOrderId'] as String? ?? '',
      type: map['type'] as String? ?? 'unknown',
      at: ToukhFirestoreTimestamps.toDateTime(map['at']) ?? DateTime.now(),
      actorRole: map['actorRole'] as String?,
      actorId: map['actorId'] as String?,
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
    );
  }

  @override
  List<Object?> get props => [id, masterOrderId, type, at, actorRole, actorId, payload];
}
