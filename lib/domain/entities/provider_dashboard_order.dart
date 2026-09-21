import 'package:equatable/equatable.dart';
import 'package:toukh_provider/shared/shared.dart';

/// Provider-facing order row for dashboard / lists (no Firestore types).
class ProviderOrderLineItem extends Equatable {
  const ProviderOrderLineItem({
    this.itemId,
    required this.name,
    required this.quantity,
    required this.lineTotalEgp,
  });

  final String? itemId;
  final String name;
  final int quantity;
  final double lineTotalEgp;

  @override
  List<Object?> get props => [itemId, name, quantity, lineTotalEgp];
}

class ProviderOrderDashboard extends Equatable {
  const ProviderOrderDashboard({
    required this.id,
    required this.status,
    required this.statusWire,
    this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
    required this.totalEgp,
    this.orderPriceEgp,
    this.customerName,
    this.hideCustomerContact = false,
    this.items = const [],
    this.isHomeService = false,
  });

  final String id;
  final OrderStatus status;
  /// Raw status string from backend (e.g. `preparing`).
  final String statusWire;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final double totalEgp;
  /// Job price used for revenue (excludes delivery fee when known).
  final double? orderPriceEgp;
  final String? customerName;
  final bool hideCustomerContact;
  final List<ProviderOrderLineItem> items;
  final bool isHomeService;

  /// Revenue amount for analytics (order/request price).
  double get revenueEgp {
    final price = orderPriceEgp;
    if (price != null && price > 0) return price;
    return totalEgp;
  }

  bool get isCancelled =>
      status == OrderStatus.cancelled ||
      statusWire == 'rejected' ||
      statusWire == 'declined';

  bool get isDelivered =>
      status == OrderStatus.delivered || statusWire == 'completed';

  /// Accepted by workflow or past placement — used for completion ratio.
  bool get reachedAcceptedStage {
    if (isHomeService) {
      return !isCancelled &&
          statusWire != 'pending' &&
          statusWire != 'tendering' &&
          statusWire != 'quoted' &&
          statusWire != 'awaiting_customer' &&
          statusWire != 'awaiting_provider';
    }
    return acceptedAt != null ||
        status == OrderStatus.accepted ||
        status == OrderStatus.pickedUp ||
        isDelivered;
  }

  /// Active kitchen / fulfillment — not delivered or cancelled.
  bool get isInProgress =>
      !isCancelled &&
      !isDelivered &&
      (status == OrderStatus.placed ||
          status == OrderStatus.accepted ||
          status == OrderStatus.pickedUp ||
          _merchantInProgressWire(statusWire));

  static bool _merchantInProgressWire(String wire) {
    final v = wire.toLowerCase().replaceAll('-', '_');
    return v == 'preparing' ||
        v == 'ready' ||
        v == 'ready_for_pickup' ||
        v == 'pending' ||
        v == 'courier_requested' ||
        v == 'courier_assigned';
  }

  @override
  List<Object?> get props => [
        id,
        status,
        statusWire,
        createdAt,
        acceptedAt,
        deliveredAt,
        totalEgp,
        orderPriceEgp,
        customerName,
        hideCustomerContact,
        items,
        isHomeService,
      ];
}
