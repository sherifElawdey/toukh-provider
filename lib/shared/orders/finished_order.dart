import 'package:equatable/equatable.dart';

import 'global_order_status.dart';
import 'master_order.dart';
import 'toukh_firestore_timestamps.dart';

/// Terminal snapshot archived to `finishedOrders/{masterOrderId}`.
class FinishedOrder extends Equatable {
  const FinishedOrder({
    required this.masterOrderId,
    required this.order,
    required this.terminalStatus,
    this.finishedAt,
  });

  final String masterOrderId;
  final MasterOrder order;
  final GlobalOrderStatus terminalStatus;
  final DateTime? finishedAt;

  factory FinishedOrder.fromMap(String id, Map<String, dynamic> map) {
    final nested = map['order'];
    final orderMap = nested is Map
        ? Map<String, dynamic>.from(nested)
        : Map<String, dynamic>.from(map);
    return FinishedOrder(
      masterOrderId: id,
      order: MasterOrder.fromMap(id, orderMap),
      terminalStatus: GlobalOrderStatus.fromWire(
        map['terminalStatus'] as String? ?? orderMap['globalStatus'] as String?,
      ),
      finishedAt: ToukhFirestoreTimestamps.toDateTime(map['finishedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final driverIds = <String>{};
    final assignmentId = order.driverAssignment?.driverId.trim();
    if (assignmentId != null && assignmentId.isNotEmpty) {
      driverIds.add(assignmentId);
    }
    for (final slice in order.providerSlices.values) {
      final id = slice.driverId?.trim();
      if (id != null && id.isNotEmpty) driverIds.add(id);
    }
    return {
      'masterOrderId': masterOrderId,
      'order': order.toMap(),
      'terminalStatus': terminalStatus.wireValue,
      if (finishedAt != null)
        'finishedAt': ToukhFirestoreTimestamps.fieldFromDateTime(finishedAt),
      'providerIds': order.providerIds,
      'driverIds': driverIds.toList(),
    };
  }

  @override
  List<Object?> get props =>
      [masterOrderId, order, terminalStatus, finishedAt];
}
