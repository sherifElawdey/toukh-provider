import 'package:equatable/equatable.dart';

import '../models/location.dart';
import 'fulfillment_mode.dart';
import 'order_cancelled_by_role.dart';
import 'pharmacy_quote.dart';
import 'provider_order_slice_line_item.dart';
import 'provider_order_status_wire.dart';
import 'provider_sub_state.dart';
import 'toukh_firestore_timestamps.dart';

/// Merchant-facing slice embedded in [MasterOrder.providerSlices].
class ProviderOrderSlice extends Equatable {
  const ProviderOrderSlice({
    required this.providerId,
    this.status = ProviderOrderStatusWire.placed,
    this.providerState = 'pending',
    this.fulfillmentMode = FulfillmentMode.courier,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerPhotoUrl,
    this.customerFcmToken,
    this.storeLocation,
    this.deliveryAddress,
    this.orderPriceEgp = 0,
    this.deliveryFeeEgp = 0,
    this.totalEgp = 0,
    this.note,
    this.driverId,
    this.driverName,
    this.driverPhotoUrl,
    this.driverPhone,
    this.deliveryRequestId,
    this.createdAt,
    this.acceptedAt,
    this.deliveryRequestedAt,
    this.readyForPickupAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelReason,
    this.cancelledByRole,
    this.items = const [],
    this.courierLateWarningAt,
    this.isAggregated = false,
    this.masterProviderCount = 1,
    this.pharmacyQuote,
    this.prescriptionImageUrl,
    this.providerBrandImageUrl,
    this.ratingAvg = 0,
  });

  final String providerId;
  final String status;
  final String providerState;
  final FulfillmentMode fulfillmentMode;

  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerPhotoUrl;
  final String? customerFcmToken;

  final Location? storeLocation;
  final Location? deliveryAddress;

  final double orderPriceEgp;
  final double deliveryFeeEgp;
  final double totalEgp;
  final String? note;

  final String? driverId;
  final String? driverName;
  final String? driverPhotoUrl;
  final String? driverPhone;
  final String? deliveryRequestId;

  final DateTime? createdAt;
  final DateTime? acceptedAt;
  /// When this slice (or shared master search) last requested a driver.
  final DateTime? deliveryRequestedAt;
  final DateTime? readyForPickupAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final OrderCancelledByRole? cancelledByRole;

  final List<ProviderOrderSliceLineItem> items;
  final DateTime? courierLateWarningAt;
  final bool isAggregated;
  final int masterProviderCount;
  final PharmacyQuote? pharmacyQuote;
  final String? prescriptionImageUrl;
  final String? providerBrandImageUrl;
  final double ratingAvg;

  String get statusWire => ProviderOrderStatusWire.normalize(status);

  bool get isQuoted =>
      providerState == ProviderSubState.quoted.wireValue ||
      statusWire == ProviderOrderStatusWire.quoted;

  bool get isGroupOrder => masterProviderCount > 1;
  bool get isStoreDelivery => fulfillmentMode == FulfillmentMode.store;
  bool get hasAssignedDriver =>
      driverId != null && driverId!.trim().isNotEmpty;
  bool get isIncoming => ProviderOrderStatusWire.isIncoming(statusWire);
  bool get isInProgress => ProviderOrderStatusWire.isInProgress(statusWire);
  bool get isOutgoing => ProviderOrderStatusWire.isOutgoing(statusWire);
  bool get isDelivered => ProviderOrderStatusWire.isDelivered(statusWire);
  bool get isTerminal => ProviderOrderStatusWire.isTerminal(statusWire);

  factory ProviderOrderSlice.fromMap(String providerId, Map<String, dynamic> m) {
    final itemsRaw = m['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => ProviderOrderSliceLineItem.fromMap(
              Map<String, dynamic>.from(e as Map),
            ))
        .where((e) => e.name.isNotEmpty)
        .toList();

    final orderPrice = _double(m['orderPrice']) ??
        _double(m['orderPriceEgp']) ??
        _double(m['subtotalEgp']) ??
        items.fold<double>(0, (a, b) => a + b.lineTotalEgp);
    final deliveryFee = _double(m['deliveryPrice']) ??
        _double(m['deliveryFeeEgp']) ??
        0.0;
    final total = _double(m['totalEgp']) ??
        _double(m['total']) ??
        (orderPrice + deliveryFee);

    return ProviderOrderSlice(
      providerId: providerId,
      status: ProviderOrderStatusWire.normalize(m['status'] as String?),
      providerState: _string(m['providerState']) ?? 'pending',
      fulfillmentMode: FulfillmentMode.fromWire(m['fulfillmentMode'] as String?),
      customerId: _string(m['customerId']) ?? _string(m['clientId']),
      customerName: _string(m['customerName']) ?? _string(m['clientName']),
      customerPhone: _string(m['customerPhone']) ?? _string(m['clientPhone']),
      customerPhotoUrl: _string(m['customerPhotoUrl']) ??
          _string(m['clientPhotoUrl']),
      customerFcmToken: _string(m['customerFcmToken']),
      storeLocation: _location(m['storeLocation']),
      deliveryAddress: _location(m['deliveryAddress']) ??
          _location(m['deliveryLocation']),
      orderPriceEgp: orderPrice,
      deliveryFeeEgp: deliveryFee,
      totalEgp: total,
      note: _string(m['note']),
      driverId: _string(m['driverId']),
      driverName: _string(m['driverName']),
      driverPhotoUrl: _string(m['driverPhotoUrl']),
      driverPhone: _string(m['driverPhone']),
      deliveryRequestId: _string(m['deliveryRequestId']),
      createdAt: ToukhFirestoreTimestamps.toDateTime(m['createdAt']) ??
          ToukhFirestoreTimestamps.toDateTime(m['placedAt']),
      acceptedAt: ToukhFirestoreTimestamps.toDateTime(m['acceptedAt']),
      deliveryRequestedAt:
          ToukhFirestoreTimestamps.toDateTime(m['deliveryRequestedAt']),
      readyForPickupAt:
          ToukhFirestoreTimestamps.toDateTime(m['readyForPickupAt']),
      dispatchedAt: ToukhFirestoreTimestamps.toDateTime(m['dispatchedAt']),
      deliveredAt: ToukhFirestoreTimestamps.toDateTime(m['deliveredAt']) ??
          ToukhFirestoreTimestamps.toDateTime(m['completedAt']),
      cancelledAt: ToukhFirestoreTimestamps.toDateTime(m['cancelledAt']),
      cancelReason: _string(m['cancelReason']),
      cancelledByRole:
          OrderCancelledByRole.fromWire(m['cancelledByRole'] as String?),
      items: items,
      courierLateWarningAt:
          ToukhFirestoreTimestamps.toDateTime(m['courierLateWarningAt']),
      isAggregated: m['isAggregated'] == true,
      masterProviderCount: _int(m['masterProviderCount']) ?? 1,
      pharmacyQuote: m['pharmacyQuote'] is Map
          ? PharmacyQuote.fromMap(
              Map<String, dynamic>.from(m['pharmacyQuote'] as Map),
            )
          : null,
      prescriptionImageUrl: _string(m['prescriptionImageUrl']),
      providerBrandImageUrl: _string(m['brandImageUrl']) ??
          _string(m['providerBrandImageUrl']),
      ratingAvg: _double(m['ratingAvg']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': statusWire,
        'providerState': providerState,
        'fulfillmentMode': fulfillmentMode.wireValue,
        if (customerId != null) 'customerId': customerId,
        if (customerName != null) 'customerName': customerName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerPhotoUrl != null) 'customerPhotoUrl': customerPhotoUrl,
        if (customerFcmToken != null) 'customerFcmToken': customerFcmToken,
        if (storeLocation != null) 'storeLocation': storeLocation!.toMap(),
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress!.toMap(),
        'orderPrice': orderPriceEgp,
        'orderPriceEgp': orderPriceEgp,
        'deliveryPrice': deliveryFeeEgp,
        'deliveryFeeEgp': deliveryFeeEgp,
        'totalEgp': totalEgp,
        if (note != null) 'note': note,
        if (driverId != null) 'driverId': driverId,
        if (driverName != null) 'driverName': driverName,
        if (driverPhotoUrl != null) 'driverPhotoUrl': driverPhotoUrl,
        if (driverPhone != null) 'driverPhone': driverPhone,
        if (deliveryRequestId != null) 'deliveryRequestId': deliveryRequestId,
        if (createdAt != null)
          'createdAt': ToukhFirestoreTimestamps.fieldFromDateTime(createdAt),
        if (acceptedAt != null)
          'acceptedAt': ToukhFirestoreTimestamps.fieldFromDateTime(acceptedAt),
        if (deliveryRequestedAt != null)
          'deliveryRequestedAt':
              ToukhFirestoreTimestamps.fieldFromDateTime(deliveryRequestedAt),
        if (readyForPickupAt != null)
          'readyForPickupAt':
              ToukhFirestoreTimestamps.fieldFromDateTime(readyForPickupAt),
        if (dispatchedAt != null)
          'dispatchedAt': ToukhFirestoreTimestamps.fieldFromDateTime(dispatchedAt),
        if (deliveredAt != null)
          'deliveredAt': ToukhFirestoreTimestamps.fieldFromDateTime(deliveredAt),
        if (cancelledAt != null)
          'cancelledAt': ToukhFirestoreTimestamps.fieldFromDateTime(cancelledAt),
        if (cancelReason != null) 'cancelReason': cancelReason,
        if (cancelledByRole != null)
          'cancelledByRole': cancelledByRole!.wireValue,
        'items': items.map((e) => e.toMap()).toList(),
        if (courierLateWarningAt != null)
          'courierLateWarningAt':
              ToukhFirestoreTimestamps.fieldFromDateTime(courierLateWarningAt),
        'isAggregated': isAggregated,
        'masterProviderCount': masterProviderCount,
        if (pharmacyQuote != null) 'pharmacyQuote': pharmacyQuote!.toMap(),
        if (prescriptionImageUrl != null)
          'prescriptionImageUrl': prescriptionImageUrl,
        if (providerBrandImageUrl != null)
          'brandImageUrl': providerBrandImageUrl,
        if (ratingAvg > 0) 'ratingAvg': ratingAvg,
      };

  static Location? _location(dynamic v) {
    if (v is! Map) return null;
    return Location.fromMap(Map<String, dynamic>.from(v));
  }

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static double? _double(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }

  @override
  List<Object?> get props => [
        providerId,
        status,
        providerState,
        fulfillmentMode,
        customerId,
        customerName,
        customerPhone,
        customerPhotoUrl,
        customerFcmToken,
        storeLocation,
        deliveryAddress,
        orderPriceEgp,
        deliveryFeeEgp,
        totalEgp,
        note,
        driverId,
        driverName,
        driverPhotoUrl,
        driverPhone,
        deliveryRequestId,
        createdAt,
        acceptedAt,
        deliveryRequestedAt,
        readyForPickupAt,
        dispatchedAt,
        deliveredAt,
        cancelledAt,
        cancelReason,
        cancelledByRole,
        items,
        courierLateWarningAt,
        isAggregated,
        masterProviderCount,
        pharmacyQuote,
        prescriptionImageUrl,
        providerBrandImageUrl,
        ratingAvg,
      ];
}
