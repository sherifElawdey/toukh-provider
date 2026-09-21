import '../models/location.dart';
import '../settings/order_acceptance_sla.dart';
import 'fulfillment_mode.dart';
import 'global_order_status.dart';
import 'master_order.dart';
import 'provider_order_slice.dart';
import 'provider_order_status_wire.dart';
import 'provider_sub_state.dart';

/// Visual urgency for incoming orders based on wait time since placement.
enum IncomingOrderUrgency { normal, warning, critical }

enum ProviderOrdersTab { incoming, inProgress, outgoing, delivered }

enum ProviderOrdersSort { newest, oldest }

/// How long a driver search stays active before re-request is allowed.
const Duration kDriverSearchTimeout = Duration(minutes: 15);

extension MasterOrderProviderX on MasterOrder {
  ProviderOrderSlice? sliceFor(String providerId) =>
      providerSlices[providerId];

  /// True when [providerId] appears in [providerOrderRefs].
  bool includesProvider(String providerId) =>
      providerOrderRefs.any((r) => r.providerId == providerId);

  /// Membership in [providerSlices]; pharmacy broadcasts may omit refs until quote.
  bool hasProviderSlice(String providerId) {
    if (!providerSlices.containsKey(providerId)) return false;
    if (isPharmacyRequest && includesProvider(providerId)) return true;
    if (isPharmacyRequest && providerIds.contains(providerId)) return true;
    return includesProvider(providerId);
  }

  bool isActiveForProvider(String providerId) {
    if (globalStatus.isTerminal) return false;
    final slice = sliceFor(providerId);
    if (slice == null) return false;
    return !slice.isTerminal;
  }

  bool isFinishedForProvider(String providerId) {
    final slice = sliceFor(providerId);
    if (slice == null) return false;
    return slice.isTerminal || globalStatus.isTerminal;
  }

  bool get isGroupOrder =>
      providerIds.length > 1 ||
      providerSlices.values.any((s) => s.masterProviderCount > 1) ||
      isAggregated;

  /// True when no other provider has accepted/progressed yet (pre-approve check).
  bool wouldBeFirstAccepter(String providerId) {
    if (!isGroupOrder) return false;
    for (final entry in providerSlices.entries) {
      if (entry.key == providerId) continue;
      final w = entry.value.statusWire;
      if (ProviderOrderStatusWire.isIncoming(w)) continue;
      if (w == ProviderOrderStatusWire.cancelled) continue;
      return false;
    }
    return true;
  }

  DateTime? get effectiveDeliveryRequestedAt {
    if (deliveryRequestedAt != null) return deliveryRequestedAt;
    DateTime? earliest;
    for (final s in providerSlices.values) {
      final at = s.deliveryRequestedAt;
      if (at == null) continue;
      if (earliest == null || at.isBefore(earliest)) earliest = at;
    }
    return earliest;
  }

  bool isDriverSearchExpired({DateTime? now}) {
    final at = effectiveDeliveryRequestedAt;
    // Missing start: do not lock forever via model; UI local timer handles it.
    // Prefer [ProviderMasterOrderRowActionsX.effectiveDeliveryRequestedAt] fallbacks.
    if (at == null) return false;
    final n = (now ?? DateTime.now()).toUtc();
    return !n.difference(at.toUtc()).isNegative &&
        n.difference(at.toUtc()) >= kDriverSearchTimeout;
  }

  bool get hasAssignedDriver =>
      (driverAssignment?.driverId.trim().isNotEmpty ?? false) ||
      providerSlices.values.any((s) => s.hasAssignedDriver);

  /// Active shared search that other providers should join (not create another).
  bool get hasActiveDriverSearch {
    if (hasAssignedDriver) return false;
    if (isDriverSearchExpired()) return false;
    if (globalStatus == GlobalOrderStatus.searchingDriver) return true;
    if (driverSearchRequestId != null && driverSearchRequestId!.isNotEmpty) {
      return true;
    }
    return providerSlices.values.any(
      (s) => s.statusWire == ProviderOrderStatusWire.courierRequested,
    );
  }
}

extension ProviderOrderSliceActionsX on ProviderOrderSlice {
  /// Courier marketplace request — before assignment (includes re-request).
  /// Prefer [ProviderMasterOrderRowActionsX] when master context is available.
  bool get canRequestDelivery =>
      fulfillmentMode != FulfillmentMode.pickup &&
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
          statusWire == ProviderOrderStatusWire.preparing ||
          statusWire == ProviderOrderStatusWire.courierRequested);

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

  /// Show courier-late banner only while still awaiting pickup.
  bool get showCourierLateWarning {
    if (courierLateWarningAt == null) return false;
    final w = statusWire;
    if (w == ProviderOrderStatusWire.pickedUp ||
        w == ProviderOrderStatusWire.outForDelivery ||
        w == ProviderOrderStatusWire.delivered ||
        w == ProviderOrderStatusWire.cancelled ||
        w == ProviderOrderStatusWire.completed) {
      return false;
    }
    return w == ProviderOrderStatusWire.readyForPickup ||
        w == ProviderOrderStatusWire.courierAssigned ||
        w == ProviderOrderStatusWire.courierRequested ||
        w == ProviderOrderStatusWire.preparing ||
        w == ProviderOrderStatusWire.accepted;
  }
}

extension ProviderMasterOrderRowActionsX on ProviderMasterOrderRow {
  bool get hasAssignedDriverEffective =>
      slice.hasAssignedDriver || master.hasAssignedDriver;

  /// Best-known start of the current driver search.
  DateTime? get effectiveDeliveryRequestedAt {
    final fromSlice = slice.deliveryRequestedAt;
    if (fromSlice != null) return fromSlice;
    final fromMaster = master.effectiveDeliveryRequestedAt;
    if (fromMaster != null) return fromMaster;
    // Last resort while still searching: master updatedAt as approximate start.
    if (slice.statusWire == ProviderOrderStatusWire.courierRequested ||
        master.globalStatus == GlobalOrderStatus.searchingDriver) {
      return master.updatedAt;
    }
    return null;
  }

  bool isDriverSearchExpired({DateTime? now}) {
    final at = effectiveDeliveryRequestedAt;
    if (at == null) {
      // No measurable start — unlock re-request only after UI-side timeout;
      // keep searching so the count-up panel can start from mount.
      return false;
    }
    final n = (now ?? DateTime.now()).toUtc();
    return !n.difference(at.toUtc()).isNegative &&
        n.difference(at.toUtc()) >= kDriverSearchTimeout;
  }

  Duration driverSearchElapsed({DateTime? now}) {
    final at = effectiveDeliveryRequestedAt;
    if (at == null) return Duration.zero;
    final diff = (now ?? DateTime.now()).toUtc().difference(at.toUtc());
    return diff.isNegative ? Duration.zero : diff;
  }

  Duration driverSearchRemaining({DateTime? now}) {
    final left = kDriverSearchTimeout - driverSearchElapsed(now: now);
    return left.isNegative ? Duration.zero : left;
  }

  bool get _isCourierEligible =>
      slice.fulfillmentMode != FulfillmentMode.pickup &&
      !slice.isStoreDelivery &&
      !slice.isTerminal;

  bool get _statusAllowsDriverRequest {
    final w = slice.statusWire;
    return w == ProviderOrderStatusWire.accepted ||
        w == ProviderOrderStatusWire.preparing ||
        w == ProviderOrderStatusWire.courierRequested ||
        w == ProviderOrderStatusWire.courierAssigned;
  }

  /// Searching UI while an open request has not expired and no driver yet.
  bool get isSearchingForDriver {
    if (!_isCourierEligible || hasAssignedDriverEffective) return false;
    if (isDriverSearchExpired()) return false;
    if (slice.statusWire == ProviderOrderStatusWire.courierRequested) {
      return true;
    }
    return master.hasActiveDriverSearch && _statusAllowsDriverRequest;
  }

  /// Request or re-request a driver (hidden while an active search is running).
  bool get canRequestDelivery {
    if (!_isCourierEligible || hasAssignedDriverEffective) return false;
    if (isSearchingForDriver) return false;
    final w = slice.statusWire;
    final baseOk = w == ProviderOrderStatusWire.accepted ||
        w == ProviderOrderStatusWire.preparing ||
        w == ProviderOrderStatusWire.courierRequested;
    if (!baseOk) return false;
    if (w == ProviderOrderStatusWire.courierRequested) {
      return isDriverSearchExpired();
    }
    // Group: join active search instead of creating a parallel request.
    if (master.hasActiveDriverSearch && !isDriverSearchExpired()) {
      return false;
    }
    return true;
  }

  bool get showRerequestDriverLabel =>
      canRequestDelivery &&
      (slice.statusWire == ProviderOrderStatusWire.courierRequested ||
          (master.driverSearchRequestId?.isNotEmpty ?? false) ||
          effectiveDeliveryRequestedAt != null);

  bool get canMarkReadyForPickup {
    if (slice.isStoreDelivery || slice.isTerminal) return false;
    if (!hasAssignedDriverEffective) return false;
    final w = slice.statusWire;
    return w == ProviderOrderStatusWire.courierAssigned ||
        w == ProviderOrderStatusWire.accepted ||
        w == ProviderOrderStatusWire.preparing ||
        w == ProviderOrderStatusWire.courierRequested;
  }

  bool get canStoreDeliver {
    if (!slice.isStoreDelivery || slice.isOutgoing || slice.isTerminal) {
      return false;
    }
    final w = slice.statusWire;
    if (w != ProviderOrderStatusWire.accepted &&
        w != ProviderOrderStatusWire.preparing) {
      return false;
    }
    // First assign, or reassign while still waiting for driver accept.
    return true;
  }

  /// Soft store assign pending — driver has not accepted yet.
  bool get isAwaitingStoreDriverAccept {
    if (!slice.isStoreDelivery || slice.isOutgoing || slice.isTerminal) {
      return false;
    }
    if (!hasAssignedDriverEffective) return false;
    final assignment = master.driverAssignment;
    if (assignment == null || assignment.driverId.trim().isEmpty) {
      return false;
    }
    final reqId = assignment.deliveryRequestId?.trim() ?? '';
    if (reqId.isNotEmpty) return false;
    if (assignment.acceptedAt != null) return false;
    final st = assignment.status.trim();
    return st.isEmpty || st == 'assigned';
  }

  bool get canConfirmHandoff => false;

  /// Courier orders ready for pickup: show QR for the driver to scan.
  bool get canShowPickupQr =>
      !slice.isStoreDelivery &&
      hasAssignedDriverEffective &&
      slice.statusWire == ProviderOrderStatusWire.readyForPickup;

  bool get shouldOpenRequestSheetAfterApprove =>
      master.wouldBeFirstAccepter(providerId) &&
      slice.fulfillmentMode != FulfillmentMode.pickup &&
      !slice.isStoreDelivery;
}

DateTime? providerSlicePlacementTime(ProviderOrderSlice? slice) =>
    slice?.createdAt;

Duration providerIncomingOrderElapsedSince(DateTime? placedAt) {
  if (placedAt == null) return Duration.zero;
  final diff = DateTime.now().toUtc().difference(placedAt.toUtc());
  return diff.isNegative ? Duration.zero : diff;
}

IncomingOrderUrgency acceptanceUrgencyFromElapsed(
  Duration elapsed, {
  required int slaMinutes,
}) {
  if (elapsed > Duration(minutes: slaMinutes)) {
    return IncomingOrderUrgency.critical;
  }
  final warningAt = acceptanceWarningMinutes(slaMinutes);
  if (elapsed >= Duration(minutes: warningAt)) {
    return IncomingOrderUrgency.warning;
  }
  return IncomingOrderUrgency.normal;
}

IncomingOrderUrgency providerIncomingOrderUrgencyFromElapsed(
  Duration elapsed, {
  OrderAcceptanceSla? sla,
  String? serviceTypeKey,
}) {
  if (sla != null) {
    final key = serviceTypeKey ?? OrderAcceptanceSlaKeys.defaultKey;
    return acceptanceUrgencyFromElapsed(
      elapsed,
      slaMinutes: sla.minutesFor(key),
    );
  }
  if (elapsed > const Duration(minutes: 5)) {
    return IncomingOrderUrgency.critical;
  }
  if (elapsed >= const Duration(minutes: 2)) {
    return IncomingOrderUrgency.warning;
  }
  return IncomingOrderUrgency.normal;
}

IncomingOrderUrgency providerIncomingOrderUrgencyForSlice(
  ProviderOrderSlice? slice, {
  OrderAcceptanceSla? sla,
  String? serviceTypeKey,
}) {
  if (slice == null || !slice.isIncoming) {
    return IncomingOrderUrgency.normal;
  }
  final placed = providerSlicePlacementTime(slice);
  if (placed == null) return IncomingOrderUrgency.normal;
  return providerIncomingOrderUrgencyFromElapsed(
    providerIncomingOrderElapsedSince(placed),
    sla: sla,
    serviceTypeKey: serviceTypeKey,
  );
}

bool providerSliceIsOverdueIncoming(
  ProviderOrderSlice slice, {
  OrderAcceptanceSla? sla,
  String? serviceTypeKey,
}) {
  return providerIncomingOrderUrgencyForSlice(
        slice,
        sla: sla,
        serviceTypeKey: serviceTypeKey,
      ) ==
      IncomingOrderUrgency.critical;
}

/// Provider list row: master order + slice for the signed-in merchant.
class ProviderMasterOrderRow {
  const ProviderMasterOrderRow({
    required this.master,
    required this.providerId,
    required this.slice,
  });

  final MasterOrder master;
  final String providerId;
  final ProviderOrderSlice slice;

  String get id => master.id;

  factory ProviderMasterOrderRow.fromMaster(MasterOrder master, String providerId) {
    final slice = master.sliceFor(providerId);
    if (slice == null) {
      throw ArgumentError('No slice for provider $providerId on ${master.id}');
    }
    return ProviderMasterOrderRow(
      master: master,
      providerId: providerId,
      slice: slice,
    );
  }

  bool get canViewCustomerContact =>
      providerCanViewCustomerContact(master, slice);
}

/// Whether a provider may see customer name/phone for [slice] on [master].
bool providerCanViewCustomerContact(
  MasterOrder master,
  ProviderOrderSlice slice,
) {
  if (!master.isPharmacyRequest) return true;
  final ps = ProviderSubState.fromWire(slice.providerState);
  return ps == ProviderSubState.preparing ||
      ps == ProviderSubState.accepted ||
      ps == ProviderSubState.readyForPickup ||
      ps == ProviderSubState.pickedUp;
}

/// Treat placeholder "Customer" as missing so UI can show a generic label.
String? _meaningfulCustomerName(String? raw) {
  final t = raw?.trim();
  if (t == null || t.isEmpty) return null;
  if (t.toLowerCase() == 'customer') return null;
  return t;
}

/// Display name for provider UI — generic label when contact is hidden.
String providerDisplayCustomerName(
  MasterOrder master,
  ProviderOrderSlice slice, {
  required String genericLabel,
}) {
  if (!providerCanViewCustomerContact(master, slice)) {
    return genericLabel;
  }
  return _meaningfulCustomerName(slice.customerName) ??
      _meaningfulCustomerName(master.customerName) ??
      genericLabel;
}

/// Customer photo for provider UI — null when contact is hidden.
String? providerDisplayCustomerPhotoUrl(
  MasterOrder master,
  ProviderOrderSlice slice,
) {
  if (!providerCanViewCustomerContact(master, slice)) return null;
  final fromSlice = slice.customerPhotoUrl?.trim();
  if (fromSlice != null && fromSlice.isNotEmpty) return fromSlice;
  final fromMaster = master.customerPhotoUrl?.trim();
  if (fromMaster != null && fromMaster.isNotEmpty) return fromMaster;
  return null;
}

/// Delivery location for provider UI (slice first, then master).
Location providerDisplayDeliveryAddress(
  MasterOrder master,
  ProviderOrderSlice slice,
) {
  return slice.deliveryAddress ?? master.deliveryAddress;
}

abstract final class ProviderMasterOrderTabFilters {
  ProviderMasterOrderTabFilters._();

  static List<ProviderMasterOrderRow> rowsFor(
    List<MasterOrder> masters,
    String providerId,
  ) {
    return [
      for (final m in masters)
        if (m.hasProviderSlice(providerId))
          ProviderMasterOrderRow.fromMaster(m, providerId),
    ];
  }

  static List<ProviderMasterOrderRow> forTab(
    List<MasterOrder> masters,
    String providerId,
    ProviderOrdersTab tab,
  ) {
    final rows = masters
        .where((m) => m.hasProviderSlice(providerId))
        .map((m) => ProviderMasterOrderRow.fromMaster(m, providerId))
        .toList();
    return switch (tab) {
      ProviderOrdersTab.incoming =>
        rows.where((r) => r.slice.isIncoming).toList(),
      ProviderOrdersTab.inProgress =>
        rows.where((r) => r.slice.isInProgress).toList(),
      ProviderOrdersTab.outgoing =>
        rows.where((r) => r.slice.isOutgoing).toList(),
      ProviderOrdersTab.delivered =>
        rows.where((r) => r.slice.isDelivered).toList(),
    };
  }

  static List<ProviderMasterOrderRow> applySort(
    List<ProviderMasterOrderRow> rows,
    ProviderOrdersSort sort, {
    ProviderOrdersTab? tab,
    OrderAcceptanceSla? sla,
    String? serviceTypeKey,
  }) {
    final copy = List<ProviderMasterOrderRow>.from(rows);
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);

    if (tab == ProviderOrdersTab.incoming) {
      copy.sort((a, b) {
        final aOver = providerSliceIsOverdueIncoming(
          a.slice,
          sla: sla,
          serviceTypeKey: serviceTypeKey,
        );
        final bOver = providerSliceIsOverdueIncoming(
          b.slice,
          sla: sla,
          serviceTypeKey: serviceTypeKey,
        );
        if (aOver != bOver) return aOver ? -1 : 1;
        final at = a.slice.createdAt ?? epoch;
        final bt = b.slice.createdAt ?? epoch;
        return at.compareTo(bt);
      });
      return copy;
    }

    copy.sort((a, b) {
      final DateTime at;
      final DateTime bt;
      if (tab == ProviderOrdersTab.delivered) {
        at = a.slice.deliveredAt ?? a.slice.createdAt ?? epoch;
        bt = b.slice.deliveredAt ?? b.slice.createdAt ?? epoch;
      } else {
        at = a.slice.createdAt ?? epoch;
        bt = b.slice.createdAt ?? epoch;
      }
      return sort == ProviderOrdersSort.newest
          ? bt.compareTo(at)
          : at.compareTo(bt);
    });
    return copy;
  }

  static List<ProviderMasterOrderRow> withDeliveryPersonOnly(
    List<ProviderMasterOrderRow> rows,
  ) {
    return rows.where((r) => r.slice.hasAssignedDriver).toList();
  }

  static bool showWithCourierFilter(List<ProviderMasterOrderRow> inProgress) {
    return inProgress.any((r) => !r.slice.isStoreDelivery);
  }

  static List<ProviderMasterOrderRow> homeInProgress(
    List<MasterOrder> masters,
    String providerId,
  ) {
    return forTab(masters, providerId, ProviderOrdersTab.inProgress);
  }
}
