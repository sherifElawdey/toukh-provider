import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../models/location.dart';
import 'toukh_firestore_timestamps.dart';
import 'delivery_route_quote.dart';
import 'driver_assignment.dart';
import 'global_order_status.dart';
import 'master_order_kind.dart';
import 'order_cancelled_by_role.dart';
import 'pharmacy_request_payload.dart';
import 'provider_order_ref.dart';
import 'provider_order_slice.dart';
import 'provider_sub_state.dart';

class MasterOrder extends Equatable {
  const MasterOrder({
    required this.id,
    required this.clientId,
    required this.globalStatus,
    required this.providerOrderRefs,
    required this.deliveryAddress,
    this.providerStatusMap = const {},
    this.deliveryTaskId,
    this.driverSearchRequestId,
    this.deliveryRequestedAt,
    this.aggregatedGroupId,
    this.driverAssignment,
    this.subtotalEgp = 0,
    this.deliveryFeeEgp = 0,
    this.serviceFeeEgp = 0,
    this.serviceFeeSnapshot,
    this.totalEgp = 0,
    this.paymentMethod,
    this.isPaid = false,
    this.timelineId,
    this.ratingCompleted = false,
    this.note,
    this.providerIds = const [],
    this.providerSlices = const {},
    this.cancelledByRole,
    this.orderKind = MasterOrderKind.standard,
    this.pharmacyRequest,
    this.selectedProviderId,
    this.customerName,
    this.customerPhone,
    this.customerPhotoUrl,
    this.route,
    this.completionCode,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientId;
  final GlobalOrderStatus globalStatus;
  final List<ProviderOrderRef> providerOrderRefs;
  final Map<String, ProviderSubState> providerStatusMap;
  final Location deliveryAddress;
  final String? deliveryTaskId;
  /// Active open delivery request while searching for a driver.
  final String? driverSearchRequestId;
  /// When the current shared driver search started.
  final DateTime? deliveryRequestedAt;
  final String? aggregatedGroupId;
  final DriverAssignment? driverAssignment;
  final double subtotalEgp;
  final double deliveryFeeEgp;
  /// Customer service fee (platform), frozen at place time.
  final double serviceFeeEgp;
  /// Audit snapshot of fee settings used at place (`mode` / `percent` / `amountEgp`).
  final Map<String, dynamic>? serviceFeeSnapshot;
  final double totalEgp;
  final String? paymentMethod;
  final bool isPaid;
  final String? timelineId;
  final bool ratingCompleted;
  final String? note;
  final List<String> providerIds;
  final Map<String, ProviderOrderSlice> providerSlices;
  final OrderCancelledByRole? cancelledByRole;
  final MasterOrderKind orderKind;
  final PharmacyRequestPayload? pharmacyRequest;
  final String? selectedProviderId;
  final String? customerName;
  final String? customerPhone;
  final String? customerPhotoUrl;
  final DeliveryRouteSnapshot? route;
  final String? completionCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAggregated =>
      aggregatedGroupId != null && aggregatedGroupId!.isNotEmpty;

  bool get isPharmacyRequest => orderKind == MasterOrderKind.pharmacyRequest;

  bool get allProvidersResponded {
    if (providerStatusMap.isEmpty) return false;
    return providerStatusMap.values.every((s) => s.isResponded);
  }

  List<ProviderOrderRef> get acceptedProviders => providerOrderRefs
      .where((r) => r.providerState.countsForPickup)
      .toList();

  MasterOrder copyWith({
    GlobalOrderStatus? globalStatus,
    List<ProviderOrderRef>? providerOrderRefs,
    Map<String, ProviderSubState>? providerStatusMap,
    String? deliveryTaskId,
    String? driverSearchRequestId,
    DateTime? deliveryRequestedAt,
    DriverAssignment? driverAssignment,
    bool? ratingCompleted,
    List<String>? providerIds,
    Map<String, ProviderOrderSlice>? providerSlices,
    OrderCancelledByRole? cancelledByRole,
    MasterOrderKind? orderKind,
    PharmacyRequestPayload? pharmacyRequest,
    String? selectedProviderId,
    String? customerName,
    String? customerPhone,
    String? customerPhotoUrl,
    String? completionCode,
    DateTime? updatedAt,
  }) {
    return MasterOrder(
      id: id,
      clientId: clientId,
      globalStatus: globalStatus ?? this.globalStatus,
      providerOrderRefs: providerOrderRefs ?? this.providerOrderRefs,
      providerStatusMap: providerStatusMap ?? this.providerStatusMap,
      deliveryAddress: deliveryAddress,
      deliveryTaskId: deliveryTaskId ?? this.deliveryTaskId,
      driverSearchRequestId:
          driverSearchRequestId ?? this.driverSearchRequestId,
      deliveryRequestedAt: deliveryRequestedAt ?? this.deliveryRequestedAt,
      aggregatedGroupId: aggregatedGroupId,
      driverAssignment: driverAssignment ?? this.driverAssignment,
      subtotalEgp: subtotalEgp,
      deliveryFeeEgp: deliveryFeeEgp,
      serviceFeeEgp: serviceFeeEgp,
      serviceFeeSnapshot: serviceFeeSnapshot,
      totalEgp: totalEgp,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      timelineId: timelineId,
      ratingCompleted: ratingCompleted ?? this.ratingCompleted,
      note: note,
      providerIds: providerIds ?? this.providerIds,
      providerSlices: providerSlices ?? this.providerSlices,
      cancelledByRole: cancelledByRole ?? this.cancelledByRole,
      orderKind: orderKind ?? this.orderKind,
      pharmacyRequest: pharmacyRequest ?? this.pharmacyRequest,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerPhotoUrl: customerPhotoUrl ?? this.customerPhotoUrl,
      route: route,
      completionCode: completionCode ?? this.completionCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'clientId': clientId,
        'globalStatus': globalStatus.wireValue,
        'providerOrderRefs':
            providerOrderRefs.map((r) => r.toMap()).toList(),
        'providerStatusMap': providerStatusMap.map(
          (k, v) => MapEntry(k, v.wireValue),
        ),
        'deliveryAddress': deliveryAddress.toMap(),
        if (deliveryTaskId != null) 'deliveryTaskId': deliveryTaskId,
        if (driverSearchRequestId != null)
          'driverSearchRequestId': driverSearchRequestId,
        if (deliveryRequestedAt != null)
          'deliveryRequestedAt':
              Timestamp.fromDate(deliveryRequestedAt!.toUtc()),
        if (aggregatedGroupId != null) 'aggregatedGroupId': aggregatedGroupId,
        if (driverAssignment != null) 'driverAssignment': driverAssignment!.toMap(),
        'subtotalEgp': subtotalEgp,
        'deliveryFeeEgp': deliveryFeeEgp,
        'serviceFeeEgp': serviceFeeEgp,
        if (serviceFeeSnapshot != null) 'serviceFeeSnapshot': serviceFeeSnapshot,
        'totalEgp': totalEgp,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        'isPaid': isPaid,
        if (timelineId != null) 'timelineId': timelineId,
        'ratingCompleted': ratingCompleted,
        if (note != null) 'note': note,
        'providerIds': providerIds,
        'providerSlices': providerSlices.map(
          (k, v) => MapEntry(k, v.toMap()),
        ),
        if (cancelledByRole != null)
          'cancelledByRole': cancelledByRole!.wireValue,
        'orderKind': orderKind.wireValue,
        if (pharmacyRequest != null) 'pharmacyRequest': pharmacyRequest!.toMap(),
        if (selectedProviderId != null) 'selectedProviderId': selectedProviderId,
        if (customerName != null) 'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerPhotoUrl != null) 'customerPhotoUrl': customerPhotoUrl,
        if (route != null) 'route': route!.toMap(),
        if (completionCode != null) 'completionCode': completionCode,
        if (createdAt != null)
          'createdAt': Timestamp.fromDate(createdAt!),
        if (updatedAt != null)
          'updatedAt': Timestamp.fromDate(updatedAt!),
      };

  factory MasterOrder.fromMap(String id, Map<String, dynamic> map) {
    final refsRaw = map['providerOrderRefs'];
    final refs = refsRaw is List
        ? refsRaw
            .map((e) => ProviderOrderRef.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <ProviderOrderRef>[];

    final statusMapRaw = map['providerStatusMap'];
    final statusMap = <String, ProviderSubState>{};
    if (statusMapRaw is Map) {
      statusMapRaw.forEach((key, value) {
        statusMap['$key'] = ProviderSubState.fromWire('$value');
      });
    }

    final slicesRaw = map['providerSlices'];
    final slices = <String, ProviderOrderSlice>{};
    if (slicesRaw is Map) {
      slicesRaw.forEach((key, value) {
        if (value is Map) {
          slices['$key'] = ProviderOrderSlice.fromMap(
            '$key',
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    final idsRaw = map['providerIds'];
    final providerIds = idsRaw is List
        ? idsRaw.map((e) => '$e').toList()
        : slices.keys.toList();

    return MasterOrder(
      id: id,
      clientId: map['clientId'] as String? ?? '',
      globalStatus: GlobalOrderStatus.fromWire(map['globalStatus'] as String?),
      providerOrderRefs: refs,
      providerStatusMap: statusMap,
      deliveryAddress: Location.fromMap(
        Map<String, dynamic>.from(map['deliveryAddress'] as Map? ?? {}),
      ),
      deliveryTaskId: map['deliveryTaskId'] as String?,
      driverSearchRequestId: map['driverSearchRequestId'] as String?,
      deliveryRequestedAt: _parseDate(map['deliveryRequestedAt']),
      aggregatedGroupId: map['aggregatedGroupId'] as String?,
      driverAssignment: map['driverAssignment'] != null
          ? DriverAssignment.fromMap(
              Map<String, dynamic>.from(map['driverAssignment'] as Map),
            )
          : null,
      subtotalEgp: (map['subtotalEgp'] as num?)?.toDouble() ?? 0,
      deliveryFeeEgp: (map['deliveryFeeEgp'] as num?)?.toDouble() ?? 0,
      serviceFeeEgp: (map['serviceFeeEgp'] as num?)?.toDouble() ?? 0,
      serviceFeeSnapshot: map['serviceFeeSnapshot'] is Map
          ? Map<String, dynamic>.from(map['serviceFeeSnapshot'] as Map)
          : null,
      totalEgp: (map['totalEgp'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod'] as String?,
      isPaid: map['isPaid'] as bool? ?? false,
      timelineId: map['timelineId'] as String?,
      ratingCompleted: map['ratingCompleted'] as bool? ?? false,
      note: map['note'] as String?,
      providerIds: providerIds,
      providerSlices: slices,
      cancelledByRole:
          OrderCancelledByRole.fromWire(map['cancelledByRole'] as String?),
      orderKind: MasterOrderKind.fromWire(map['orderKind'] as String?),
      pharmacyRequest: map['pharmacyRequest'] is Map
          ? PharmacyRequestPayload.fromMap(
              Map<String, dynamic>.from(map['pharmacyRequest'] as Map),
            )
          : null,
      selectedProviderId: map['selectedProviderId'] as String?,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      customerPhotoUrl: map['customerPhotoUrl'] as String?,
      route: map['route'] is Map
          ? DeliveryRouteSnapshot.fromMap(
              Map<String, dynamic>.from(map['route'] as Map),
            )
          : null,
      completionCode: map['completionCode'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  @override
  List<Object?> get props => [
        id,
        clientId,
        globalStatus,
        providerOrderRefs,
        providerStatusMap,
        deliveryAddress,
        deliveryTaskId,
        driverSearchRequestId,
        deliveryRequestedAt,
        aggregatedGroupId,
        driverAssignment,
        subtotalEgp,
        deliveryFeeEgp,
        serviceFeeEgp,
        serviceFeeSnapshot,
        totalEgp,
        paymentMethod,
        isPaid,
        timelineId,
        ratingCompleted,
        note,
        providerIds,
        providerSlices,
        cancelledByRole,
        orderKind,
        pharmacyRequest,
        selectedProviderId,
        customerName,
        customerPhone,
        customerPhotoUrl,
        route,
        completionCode,
        createdAt,
        updatedAt,
      ];
}
