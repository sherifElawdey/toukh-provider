import 'package:equatable/equatable.dart';

import 'toukh_firestore_timestamps.dart';

class DriverAssignment extends Equatable {
  const DriverAssignment({
    required this.driverId,
    this.driverName,
    this.driverPhotoUrl,
    this.driverPhone,
    this.deliveryRequestId,
    this.assignedAt,
    this.acceptedAt,
    this.status = 'assigned',
  });

  final String driverId;
  final String? driverName;
  final String? driverPhotoUrl;
  final String? driverPhone;
  final String? deliveryRequestId;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final String status;

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        if (driverName != null) 'driverName': driverName,
        if (driverPhotoUrl != null) 'driverPhotoUrl': driverPhotoUrl,
        if (driverPhone != null) 'driverPhone': driverPhone,
        if (deliveryRequestId != null) 'deliveryRequestId': deliveryRequestId,
        if (assignedAt != null)
          'assignedAt': ToukhFirestoreTimestamps.fieldFromDateTime(assignedAt),
        if (acceptedAt != null)
          'acceptedAt': ToukhFirestoreTimestamps.fieldFromDateTime(acceptedAt),
        'status': status,
      };

  factory DriverAssignment.fromMap(Map<String, dynamic> map) {
    return DriverAssignment(
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String?,
      driverPhotoUrl: map['driverPhotoUrl'] as String?,
      driverPhone: map['driverPhone'] as String?,
      deliveryRequestId: map['deliveryRequestId'] as String?,
      assignedAt: _parseDate(map['assignedAt']),
      acceptedAt: _parseDate(map['acceptedAt']),
      status: map['status'] as String? ?? 'assigned',
    );
  }

  static DateTime? _parseDate(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  @override
  List<Object?> get props => [
        driverId,
        driverName,
        driverPhotoUrl,
        driverPhone,
        deliveryRequestId,
        assignedAt,
        acceptedAt,
        status,
      ];
}
