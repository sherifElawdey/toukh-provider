import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/data/mappers/provider_driver_mapper.dart';
import 'package:toukh_provider/domain/entities/driver_day_stats.dart';
import 'package:toukh_provider/domain/entities/provider_driver_link_request.dart';
import 'package:toukh_provider/domain/entities/provider_linked_driver.dart';
import 'package:toukh_provider/domain/repositories/provider_drivers_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderDriversRepository implements ProviderDriversRepository {
  FirestoreProviderDriversRepository(
    this._firestore,
    this._functions,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<ProviderDriversSnapshot> watchDrivers(String providerId) {
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? pendingSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? linkedSub;

    late StreamController<ProviderDriversSnapshot> controller;

    List<ProviderDriverLinkRequest> pending = [];
    List<ProviderLinkedDriver> linked = [];

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        ProviderDriversSnapshot(
          pendingRequests: List.unmodifiable(pending),
          linkedDrivers: List.unmodifiable(linked),
        ),
      );
    }

    controller = StreamController<ProviderDriversSnapshot>(
      onListen: () {
        // Couriers ask by setting `pendingProviderId` on their driver doc; the
        // store's accept moves it to the server-owned `linkedProviderId`.
        pendingSub = _firestore
            .collection(AppConstants.driversCollection)
            .where('pendingProviderId', isEqualTo: providerId)
            .snapshots()
            .listen(
              (snap) {
                pending = snap.docs
                    // Registrants show up once their phone is verified.
                    .where((d) => d.data()['status'] != 'unverified')
                    .map(
                      (d) => ProviderDriverMapper.linkRequestFromFirestore(
                        d.id,
                        d.data(),
                      ),
                    )
                    .toList();
                pending.sort((a, b) {
                  final at = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
                emit();
              },
              onError: controller.addError,
            );

        linkedSub = _firestore
            .collection(AppConstants.driversCollection)
            .where('linkedProviderId', isEqualTo: providerId)
            .snapshots()
            .listen(
              (snap) {
                linked = snap.docs
                    .map(
                      (d) => ProviderDriverMapper.linkedDriverFromFirestore(
                        d.id,
                        d.data(),
                      ),
                    )
                    .toList();
                linked.sort((a, b) => a.displayName.compareTo(b.displayName));
                emit();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await pendingSub?.cancel();
        await linkedSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<Map<String, DriverDayStats>> watchTodayStats(String providerId) {
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? activeSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? finishedSub;
    late StreamController<Map<String, DriverDayStats>> controller;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    bool isToday(DateTime? at) => at != null && !at.isBefore(startOfDay);

    var active = <String, MasterOrder>{};
    var finished = <String, FinishedOrder>{};

    String? driverOf(MasterOrder order) => AssignedDriverFields.resolve(
          slice: order.providerSlices[providerId],
          assignment: order.driverAssignment,
        ).driverId;

    void emit() {
      if (controller.isClosed) return;
      final stats = <String, DriverDayStats>{};
      void bump(String id, {int d = 0, int a = 0, int c = 0}) {
        stats[id] = (stats[id] ?? DriverDayStats.empty)
            .add(delivered: d, active: a, cancelled: c);
      }

      for (final f in finished.values) {
        final id = driverOf(f.order);
        if (id == null) continue;
        if (f.terminalStatus == GlobalOrderStatus.delivered) {
          bump(id, d: 1);
        } else if (f.terminalStatus == GlobalOrderStatus.cancelled) {
          bump(id, c: 1);
        }
      }
      for (final m in active.values) {
        // Archived copies win: the live doc may linger for a moment.
        if (finished.containsKey(m.id)) continue;
        final id = driverOf(m);
        if (id == null) continue;
        final slice = m.providerSlices[providerId];
        final wire = slice?.statusWire ?? '';
        if (ProviderOrderStatusWire.isDelivered(wire)) {
          if (isToday(slice?.deliveredAt ?? m.updatedAt)) bump(id, d: 1);
        } else if (wire == ProviderOrderStatusWire.cancelled ||
            m.globalStatus == GlobalOrderStatus.cancelled) {
          if (isToday(m.updatedAt)) bump(id, c: 1);
        } else {
          bump(id, a: 1);
        }
      }
      controller.add(Map.unmodifiable(stats));
    }

    controller = StreamController<Map<String, DriverDayStats>>(
      onListen: () {
        activeSub = _firestore
            .collection(ToukhOrderPaths.masterOrders)
            .where('providerIds', arrayContains: providerId)
            .limit(200)
            .snapshots()
            .listen(
              (snap) {
                active = {
                  for (final d in snap.docs)
                    d.id: MasterOrder.fromMap(d.id, d.data()),
                };
                emit();
              },
              onError: controller.addError,
            );

        finishedSub = _firestore
            .collection(ToukhOrderPaths.finishedOrders)
            .where('providerIds', arrayContains: providerId)
            .where(
              'finishedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .orderBy('finishedAt', descending: true)
            .snapshots()
            .listen(
              (snap) {
                finished = {
                  for (final d in snap.docs)
                    d.id: FinishedOrder.fromMap(d.id, d.data()),
                };
                emit();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await activeSub?.cancel();
        await finishedSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> respond({
    required String driverId,
    required DriverLinkAction action,
  }) async {
    final callable = _functions.httpsCallable('respondToLinkedDriver');
    await callable.call<Map<String, dynamic>>({
      'driverId': driverId,
      'action': action.name,
    });
  }
}
