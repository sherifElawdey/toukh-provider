/// Merchant order lifecycle wire values stored in Firestore `status`.
abstract final class ProviderOrderStatusWire {
  ProviderOrderStatusWire._();

  static const placed = 'placed';
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const preparing = 'preparing';
  static const courierRequested = 'courier_requested';
  static const courierAssigned = 'courier_assigned';
  static const readyForPickup = 'ready_for_pickup';
  static const pickedUp = 'picked_up';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
  static const completed = 'completed';

  static String normalize(String? raw) {
    final v = raw?.trim().toLowerCase().replaceAll('-', '_') ?? placed;
    if (v == 'new') return placed;
    if (v == 'ready') return readyForPickup;
    return v;
  }

  static bool isIncoming(String wire) {
    final w = normalize(wire);
    return w == placed || w == pending;
  }

  static bool isInProgress(String wire) {
    final w = normalize(wire);
    if (isIncoming(w) || isOutgoing(w) || isTerminal(w)) return false;
    return true;
  }

  static bool isOutgoing(String wire) {
    final w = normalize(wire);
    return w == outForDelivery || w == pickedUp;
  }

  static bool isDelivered(String wire) {
    final w = normalize(wire);
    return w == delivered || w == completed;
  }

  static bool isTerminal(String wire) {
    final w = normalize(wire);
    return w == delivered || w == completed || w == cancelled;
  }
}
