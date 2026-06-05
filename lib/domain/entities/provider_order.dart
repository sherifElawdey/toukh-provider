import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_fulfillment_mode.dart';
import 'package:toukh_provider/domain/entities/provider_order_status_wire.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Full provider-facing order for lists, detail, and actions.
class ProviderOrder extends Equatable {
  const ProviderOrder({
    required this.id,
    required this.statusWire,
    required this.fulfillmentMode,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerFcmToken,
    this.storeLocation,
    this.deliveryAddress,
    this.orderPrice = 0,
    this.deliveryPrice,
    this.totalEgp = 0,
    this.note,
    this.driverId,
    this.driverName,
    this.driverPhotoUrl,
    this.deliveryRequestId,
    this.createdAt,
    this.acceptedAt,
    this.readyForPickupAt,
    this.dispatchedAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelReason,
    this.items = const [],
    this.courierLateWarningAt,
    this.masterOrderId,
    this.isAggregated = false,
    this.providerState,
    this.masterProviderCount = 1,
  });

  final String id;
  final String statusWire;
  final ProviderFulfillmentMode fulfillmentMode;

  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerFcmToken;

  final Location? storeLocation;
  final Location? deliveryAddress;

  final double orderPrice;
  final double? deliveryPrice;
  final double totalEgp;
  final String? note;

  final String? driverId;
  final String? driverName;
  final String? driverPhotoUrl;
  final String? deliveryRequestId;

  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? readyForPickupAt;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelReason;

  final List<ProviderOrderLineItem> items;
  final DateTime? courierLateWarningAt;
  final String? masterOrderId;
  final bool isAggregated;
  final String? providerState;
  final int masterProviderCount;

  bool get isGroupOrder => masterProviderCount > 1;

  bool get isStoreDelivery => fulfillmentMode == ProviderFulfillmentMode.store;
  bool get hasAssignedDriver =>
      driverId != null && driverId!.trim().isNotEmpty;

  bool get isIncoming => ProviderOrderStatusWire.isIncoming(statusWire);
  bool get isInProgress => ProviderOrderStatusWire.isInProgress(statusWire);
  bool get isOutgoing => ProviderOrderStatusWire.isOutgoing(statusWire);
  bool get isDelivered => ProviderOrderStatusWire.isDelivered(statusWire);
  bool get isTerminal => ProviderOrderStatusWire.isTerminal(statusWire);

  bool get canRequestDelivery =>
      !isAggregated &&
      !isStoreDelivery &&
      !hasAssignedDriver &&
      (statusWire == ProviderOrderStatusWire.accepted ||
          statusWire == ProviderOrderStatusWire.preparing ||
          statusWire == ProviderOrderStatusWire.courierRequested);

  bool get canMarkReadyForPickup =>
      !isStoreDelivery &&
      hasAssignedDriver &&
      (statusWire == ProviderOrderStatusWire.courierAssigned ||
          statusWire == ProviderOrderStatusWire.accepted ||
          statusWire == ProviderOrderStatusWire.preparing);

  bool get canStoreDeliver =>
      isStoreDelivery &&
      !isOutgoing &&
      !isTerminal &&
      (statusWire == ProviderOrderStatusWire.accepted ||
          statusWire == ProviderOrderStatusWire.preparing);

  bool get canConfirmHandoff =>
      !isStoreDelivery &&
      hasAssignedDriver &&
      statusWire == ProviderOrderStatusWire.readyForPickup;

  OrderStatus get coarseStatus {
    final w = ProviderOrderStatusWire.normalize(statusWire);
    if (w == ProviderOrderStatusWire.cancelled) return OrderStatus.cancelled;
    if (w == ProviderOrderStatusWire.delivered ||
        w == ProviderOrderStatusWire.completed) {
      return OrderStatus.delivered;
    }
    if (w == ProviderOrderStatusWire.outForDelivery ||
        w == ProviderOrderStatusWire.pickedUp) {
      return OrderStatus.pickedUp;
    }
    if (w == ProviderOrderStatusWire.placed ||
        w == ProviderOrderStatusWire.pending) {
      return OrderStatus.placed;
    }
    return OrderStatus.accepted;
  }

  ProviderOrderDashboard toDashboard() {
    return ProviderOrderDashboard(
      id: id,
      status: coarseStatus,
      statusWire: statusWire,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      deliveredAt: deliveredAt ?? (dispatchedAt),
      totalEgp: totalEgp,
      customerName: customerName,
      items: items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        statusWire,
        fulfillmentMode,
        customerId,
        customerName,
        customerPhone,
        customerFcmToken,
        storeLocation,
        deliveryAddress,
        orderPrice,
        deliveryPrice,
        totalEgp,
        note,
        driverId,
        driverName,
        driverPhotoUrl,
        deliveryRequestId,
        createdAt,
        acceptedAt,
        readyForPickupAt,
        dispatchedAt,
        deliveredAt,
        cancelledAt,
        cancelReason,
        items,
        courierLateWarningAt,
        masterOrderId,
        isAggregated,
        providerState,
        masterProviderCount,
      ];
}

/// Incoming orders waiting more than five minutes since placement.
bool providerOrderIsOverdueIncoming(ProviderOrder order) {
  if (!order.isIncoming) return false;
  final created = order.createdAt;
  if (created == null) return false;
  return DateTime.now().difference(created) > const Duration(minutes: 5);
}

/// Tab filters for the provider orders screen.
enum ProviderOrdersTab { incoming, inProgress, outgoing, delivered }

enum ProviderOrdersSort { newest, oldest }

abstract final class ProviderOrderTabFilters {
  ProviderOrderTabFilters._();

  static List<ProviderOrder> forTab(
    List<ProviderOrder> orders,
    ProviderOrdersTab tab,
  ) {
    return switch (tab) {
      ProviderOrdersTab.incoming =>
        orders.where((o) => o.isIncoming).toList(),
      ProviderOrdersTab.inProgress =>
        orders.where((o) => o.isInProgress).toList(),
      ProviderOrdersTab.outgoing =>
        orders.where((o) => o.isOutgoing).toList(),
      ProviderOrdersTab.delivered =>
        orders.where((o) => o.isDelivered).toList(),
    };
  }

  static List<ProviderOrder> applySort(
    List<ProviderOrder> orders,
    ProviderOrdersSort sort, {
    ProviderOrdersTab? tab,
  }) {
    final copy = List<ProviderOrder>.from(orders);
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);

    if (tab == ProviderOrdersTab.incoming) {
      copy.sort((a, b) {
        final aOver = providerOrderIsOverdueIncoming(a);
        final bOver = providerOrderIsOverdueIncoming(b);
        if (aOver != bOver) return aOver ? -1 : 1;
        final at = a.createdAt ?? epoch;
        final bt = b.createdAt ?? epoch;
        return at.compareTo(bt);
      });
      return copy;
    }

    copy.sort((a, b) {
      final DateTime at;
      final DateTime bt;
      if (tab == ProviderOrdersTab.delivered) {
        at = a.deliveredAt ?? a.createdAt ?? epoch;
        bt = b.deliveredAt ?? b.createdAt ?? epoch;
      } else {
        at = a.createdAt ?? epoch;
        bt = b.createdAt ?? epoch;
      }
      return sort == ProviderOrdersSort.newest
          ? bt.compareTo(at)
          : at.compareTo(bt);
    });
    return copy;
  }

  static List<ProviderOrder> withDeliveryPersonOnly(List<ProviderOrder> orders) {
    return orders.where((o) => o.hasAssignedDriver).toList();
  }

  static bool showWithCourierFilter(List<ProviderOrder> inProgress) {
    return inProgress.any((o) => !o.isStoreDelivery);
  }

  /// Home dashboard in-progress strip (same rules as in-progress tab).
  static List<ProviderOrder> homeInProgress(List<ProviderOrder> orders) {
    return forTab(orders, ProviderOrdersTab.inProgress);
  }
}
