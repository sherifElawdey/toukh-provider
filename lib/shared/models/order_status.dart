/// Lifecycle of an order from creation to terminal state.
enum OrderStatus {
  /// Created by the client; not yet accepted by a driver.
  placed,
  /// A driver accepted; awaiting client confirmation / pickup.
  accepted,
  /// Driver picked up items from the merchant / pickup location.
  pickedUp,
  /// Items handed over to the client.
  delivered,
  /// Cancelled (by client, driver, or system).
  cancelled;
  /// Wire value used in transport / persistence layers.
  String get wireValue {
    switch (this) {
      case OrderStatus.placed:
        return 'placed';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Lenient parser; falls back to [OrderStatus.placed] on unknown / null
  /// inputs to keep clients resilient to backend additions.
  static OrderStatus fromWire(String? raw) {
    final v = raw?.trim().toLowerCase().replaceAll('-', '_');
    switch (v) {
      case 'placed':
      case 'pending':
      case 'new':
        return OrderStatus.placed;
      case 'accepted':
      case 'assigned':
        return OrderStatus.accepted;
      case 'picked_up':
      case 'pickedup':
      case 'in_transit':
        return OrderStatus.pickedUp;
      case 'delivered':
      case 'completed':
      case 'finished':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.placed;
    }
  }
}
