import 'package:equatable/equatable.dart';

import 'fulfillment_mode.dart';
import 'order_cancelled_by_role.dart';
import 'provider_sub_state.dart';
import 'toukh_firestore_timestamps.dart';

class ProviderOrderRef extends Equatable {
  const ProviderOrderRef({
    required this.providerId,
    required this.providerOrderId,
    required this.providerState,
    required this.fulfillmentMode,
    this.providerName,
    this.orderPriceEgp = 0,
    this.deliveryFeeEgp = 0,
    this.isAggregated = false,
    this.cancelledAt,
    this.cancelReason,
    this.cancelledByRole,
  });

  final String providerId;
  final String providerOrderId;
  final ProviderSubState providerState;
  final FulfillmentMode fulfillmentMode;
  final String? providerName;
  final double orderPriceEgp;
  final double deliveryFeeEgp;
  final bool isAggregated;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final OrderCancelledByRole? cancelledByRole;

  double get totalEgp => orderPriceEgp + deliveryFeeEgp;

  ProviderOrderRef copyWith({
    ProviderSubState? providerState,
    FulfillmentMode? fulfillmentMode,
    double? deliveryFeeEgp,
    DateTime? cancelledAt,
    String? cancelReason,
    OrderCancelledByRole? cancelledByRole,
  }) {
    return ProviderOrderRef(
      providerId: providerId,
      providerOrderId: providerOrderId,
      providerState: providerState ?? this.providerState,
      fulfillmentMode: fulfillmentMode ?? this.fulfillmentMode,
      providerName: providerName,
      orderPriceEgp: orderPriceEgp,
      deliveryFeeEgp: deliveryFeeEgp ?? this.deliveryFeeEgp,
      isAggregated: isAggregated,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledByRole: cancelledByRole ?? this.cancelledByRole,
    );
  }

  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'providerOrderId': providerOrderId,
        'providerState': providerState.wireValue,
        'fulfillmentMode': fulfillmentMode.wireValue,
        if (providerName != null) 'providerName': providerName,
        'orderPriceEgp': orderPriceEgp,
        'deliveryFeeEgp': deliveryFeeEgp,
        'isAggregated': isAggregated,
        if (cancelledAt != null)
          'cancelledAt': ToukhFirestoreTimestamps.fieldFromDateTime(cancelledAt),
        if (cancelReason != null) 'cancelReason': cancelReason,
        if (cancelledByRole != null)
          'cancelledByRole': cancelledByRole!.wireValue,
      };

  factory ProviderOrderRef.fromMap(Map<String, dynamic> map) {
    return ProviderOrderRef(
      providerId: map['providerId'] as String? ?? '',
      providerOrderId: map['providerOrderId'] as String? ?? '',
      providerState: ProviderSubState.fromWire(map['providerState'] as String?),
      fulfillmentMode: FulfillmentMode.fromWire(map['fulfillmentMode'] as String?),
      providerName: map['providerName'] as String?,
      orderPriceEgp: (map['orderPriceEgp'] as num?)?.toDouble() ?? 0,
      deliveryFeeEgp: (map['deliveryFeeEgp'] as num?)?.toDouble() ?? 0,
      isAggregated: map['isAggregated'] as bool? ?? false,
      cancelledAt: _parseDate(map['cancelledAt']),
      cancelReason: map['cancelReason'] as String?,
      cancelledByRole:
          OrderCancelledByRole.fromWire(map['cancelledByRole'] as String?),
    );
  }

  static DateTime? _parseDate(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  @override
  List<Object?> get props => [
        providerId,
        providerOrderId,
        providerState,
        fulfillmentMode,
        providerName,
        orderPriceEgp,
        deliveryFeeEgp,
        isAggregated,
        cancelledAt,
        cancelReason,
        cancelledByRole,
      ];
}
