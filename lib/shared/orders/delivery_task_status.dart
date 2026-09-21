enum DeliveryTaskStatus {
  pending,
  awaitingProviders,
  dispatching,
  assigned,
  partiallyPicked,
  pickedUp,
  onTheWay,
  delivered,
  cancelled;

  String get wireValue => switch (this) {
        DeliveryTaskStatus.pending => 'pending',
        DeliveryTaskStatus.awaitingProviders => 'awaiting_providers',
        DeliveryTaskStatus.dispatching => 'dispatching',
        DeliveryTaskStatus.assigned => 'assigned',
        DeliveryTaskStatus.partiallyPicked => 'partially_picked',
        DeliveryTaskStatus.pickedUp => 'picked_up',
        DeliveryTaskStatus.onTheWay => 'on_the_way',
        DeliveryTaskStatus.delivered => 'delivered',
        DeliveryTaskStatus.cancelled => 'cancelled',
      };

  static DeliveryTaskStatus fromWire(String? raw) =>
      switch (raw?.trim().toLowerCase()) {
        'awaiting_providers' => DeliveryTaskStatus.awaitingProviders,
        'dispatching' => DeliveryTaskStatus.dispatching,
        'assigned' => DeliveryTaskStatus.assigned,
        'partially_picked' => DeliveryTaskStatus.partiallyPicked,
        'picked_up' => DeliveryTaskStatus.pickedUp,
        'on_the_way' => DeliveryTaskStatus.onTheWay,
        'delivered' => DeliveryTaskStatus.delivered,
        'cancelled' => DeliveryTaskStatus.cancelled,
        _ => DeliveryTaskStatus.pending,
      };
}
