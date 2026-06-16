import 'package:toukh_ui/toukh_ui.dart';

/// Resolved cancellation attribution for a provider order row.
class OrderCancelAttribution {
  const OrderCancelAttribution({
    required this.role,
    required this.cancelledAt,
    this.cancelReason,
  });

  final OrderCancelledByRole role;
  final DateTime cancelledAt;
  final String? cancelReason;
}

/// Returns who canceled [row], or null when the slice is not canceled.
OrderCancelAttribution? resolveCancelAttribution(ProviderMasterOrderRow row) {
  final slice = row.slice;
  final isCancelled = slice.statusWire == ProviderOrderStatusWire.cancelled ||
      slice.providerState.toLowerCase() == 'rejected';
  if (!isCancelled) return null;

  final cancelledAt = slice.cancelledAt;
  if (cancelledAt == null) return null;

  OrderCancelledByRole? role = slice.cancelledByRole ?? row.master.cancelledByRole;
  if (role == null) {
    if (slice.providerState.toLowerCase() == 'rejected') {
      role = OrderCancelledByRole.provider;
    } else if (row.master.globalStatus == GlobalOrderStatus.cancelled) {
      role = OrderCancelledByRole.customer;
    }
  }
  role ??= OrderCancelledByRole.provider;

  return OrderCancelAttribution(
    role: role,
    cancelledAt: cancelledAt,
    cancelReason: slice.cancelReason,
  );
}
