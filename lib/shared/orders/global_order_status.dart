/// Customer-visible master order status.
enum GlobalOrderStatus {
  pending,
  awaitingPharmacySelection,
  preparing,
  searchingDriver,
  driverAssigned,
  partiallyPicked,
  pickedUp,
  onTheWay,
  delivered,
  cancelled;

  String get wireValue => switch (this) {
        GlobalOrderStatus.pending => 'pending',
        GlobalOrderStatus.awaitingPharmacySelection =>
          'awaiting_pharmacy_selection',
        GlobalOrderStatus.preparing => 'preparing',
        GlobalOrderStatus.searchingDriver => 'searching_driver',
        GlobalOrderStatus.driverAssigned => 'driver_assigned',
        GlobalOrderStatus.partiallyPicked => 'partially_picked',
        GlobalOrderStatus.pickedUp => 'picked_up',
        GlobalOrderStatus.onTheWay => 'on_the_way',
        GlobalOrderStatus.delivered => 'delivered',
        GlobalOrderStatus.cancelled => 'cancelled',
      };

  static GlobalOrderStatus fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'pending':
      case 'placed':
        return GlobalOrderStatus.pending;
      case 'awaiting_pharmacy_selection':
        return GlobalOrderStatus.awaitingPharmacySelection;
      case 'preparing':
        return GlobalOrderStatus.preparing;
      case 'searching_driver':
        return GlobalOrderStatus.searchingDriver;
      case 'driver_assigned':
      case 'courier_assigned':
        return GlobalOrderStatus.driverAssigned;
      case 'partially_picked':
        return GlobalOrderStatus.partiallyPicked;
      case 'picked_up':
        return GlobalOrderStatus.pickedUp;
      case 'on_the_way':
      case 'out_for_delivery':
        return GlobalOrderStatus.onTheWay;
      case 'delivered':
      case 'completed':
        return GlobalOrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return GlobalOrderStatus.cancelled;
      default:
        return GlobalOrderStatus.pending;
    }
  }

  bool get isTerminal =>
      this == GlobalOrderStatus.delivered ||
      this == GlobalOrderStatus.cancelled;

  bool get isAwaitingPharmacySelection =>
      this == GlobalOrderStatus.awaitingPharmacySelection;
}
