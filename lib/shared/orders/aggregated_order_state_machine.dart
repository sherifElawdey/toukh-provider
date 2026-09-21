import 'global_order_status.dart';
import 'provider_sub_state.dart';

/// Derives [GlobalOrderStatus] from per-provider states and driver progress.
abstract final class AggregatedOrderStateMachine {
  static GlobalOrderStatus derive({
    required Map<String, ProviderSubState> providerStatusMap,
    required bool hasDriver,
    required bool allAcceptedPickedUp,
    required bool anyPickedUp,
    required bool onTheWay,
    required bool delivered,
    required bool cancelled,
  }) {
    if (cancelled) return GlobalOrderStatus.cancelled;
    if (delivered) return GlobalOrderStatus.delivered;
    if (onTheWay) return GlobalOrderStatus.onTheWay;
    if (allAcceptedPickedUp) return GlobalOrderStatus.pickedUp;
    if (anyPickedUp) return GlobalOrderStatus.partiallyPicked;
    if (hasDriver) return GlobalOrderStatus.driverAssigned;

    final values = providerStatusMap.values.toList();
    if (values.isEmpty) return GlobalOrderStatus.pending;

    final anyAccepted = values.any((s) => s.countsForPickup);
    if (anyAccepted) return GlobalOrderStatus.preparing;

    return GlobalOrderStatus.pending;
  }

  static bool allProvidersResponded(Map<String, ProviderSubState> map) {
    if (map.isEmpty) return false;
    return map.values.every((s) => s.isResponded);
  }

  static List<String> acceptedProviderIds(Map<String, ProviderSubState> map) {
    return map.entries
        .where((e) => e.value.countsForPickup)
        .map((e) => e.key)
        .toList();
  }

  static bool allAcceptedPickedUp(Map<String, ProviderSubState> map) {
    final accepted = map.entries.where((e) => e.value.countsForPickup);
    if (accepted.isEmpty) return false;
    return accepted.every((e) => e.value == ProviderSubState.pickedUp);
  }
}
