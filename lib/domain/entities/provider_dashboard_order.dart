import 'package:equatable/equatable.dart';
import 'package:toukh_ui/toukh_ui.dart';

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
    this.customerName,
    this.items = const [],
  });

  final String id;
  final OrderStatus status;
  /// Raw status string from backend (e.g. `preparing`).
  final String statusWire;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final double totalEgp;
  final String? customerName;
  final List<ProviderOrderLineItem> items;

  bool get isCancelled => status == OrderStatus.cancelled;

  bool get isDelivered =>
      status == OrderStatus.delivered || statusWire == 'completed';

  /// Accepted by workflow or past placement — used for completion ratio.
  bool get reachedAcceptedStage =>
      acceptedAt != null ||
      status == OrderStatus.accepted ||
      status == OrderStatus.pickedUp ||
      isDelivered;

  /// Active kitchen / fulfillment — not delivered or cancelled.
  bool get isInProgress =>
      !isCancelled &&
      !isDelivered &&
      (status == OrderStatus.placed ||
          status == OrderStatus.accepted ||
          status == OrderStatus.pickedUp ||
          _merchantInProgressWire(statusWire));

  static bool _merchantInProgressWire(String wire) {
    final v = wire.toLowerCase();
    return v == 'preparing' ||
        v == 'ready' ||
        v == 'ready_for_pickup' ||
        v == 'pending';
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
        customerName,
        items,
      ];
}
