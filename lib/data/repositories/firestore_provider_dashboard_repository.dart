import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/domain/entities/dashboard_firestore_payload.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/data/mappers/provider_review_mapper.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';

class FirestoreProviderDashboardRepository implements ProviderDashboardRepository {
  FirestoreProviderDashboardRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviewsCol(String providerUid) =>
      _firestore.collection('providers').doc(providerUid).collection('reviews');

  @override
  Stream<DashboardFirestorePayload> watchFirestorePayload(String providerUid) {
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? activeSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? finishedSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? reviewsSub;

    late StreamController<DashboardFirestorePayload> controller;

    List<ProviderOrderDashboard> orders = [];
    List<ProviderReviewSummary> reviews = [];

    void emit() {
      if (!controller.isClosed) {
        controller.add(
          DashboardFirestorePayload(
            orders: List.unmodifiable(orders),
            reviews: List.unmodifiable(reviews),
          ),
        );
      }
    }

    controller = StreamController<DashboardFirestorePayload>(
      onListen: () {
        final activeOrders = <ProviderOrderDashboard>[];
        final finishedOrders = <ProviderOrderDashboard>[];

        activeSub = _firestore
            .collection(ToukhOrderPaths.masterOrders)
            .where('providerIds', arrayContains: providerUid)
            .limit(500)
            .snapshots()
            .listen(
              (snap) {
                activeOrders
                  ..clear()
                  ..addAll(
                    snap.docs
                        .map((d) => _mapFromMaster(d.id, d.data(), providerUid))
                        .whereType<ProviderOrderDashboard>(),
                  );
                activeOrders.sort((a, b) {
                  final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
                orders = [...activeOrders, ...finishedOrders];
                emit();
              },
              onError: controller.addError,
            );

        finishedSub = _firestore
            .collection(ToukhOrderPaths.finishedOrders)
            .where('providerIds', arrayContains: providerUid)
            .limit(500)
            .snapshots()
            .listen(
              (snap) {
                finishedOrders
                  ..clear()
                  ..addAll(
                    snap.docs
                        .map((d) {
                          final finished = FinishedOrder.fromMap(d.id, d.data());
                          return _mapFromMaster(
                            finished.masterOrderId,
                            finished.order.toMap(),
                            providerUid,
                          );
                        })
                        .whereType<ProviderOrderDashboard>(),
                  );
                finishedOrders.sort((a, b) {
                  final at = a.deliveredAt ?? a.createdAt ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = b.deliveredAt ?? b.createdAt ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
                orders = [...activeOrders, ...finishedOrders];
                emit();
              },
              onError: controller.addError,
            );

        reviewsSub = _reviewsCol(providerUid)
            .orderBy('createdAt', descending: true)
            .limit(60)
            .snapshots()
            .listen(
              (snap) {
                reviews = snap.docs
                    .map((d) => ProviderReviewMapper.fromFirestore(d.id, d.data()))
                    .toList();
                emit();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await activeSub?.cancel();
        await finishedSub?.cancel();
        await reviewsSub?.cancel();
      },
    );

    return controller.stream;
  }

  static ProviderOrderDashboard? _mapFromMaster(
    String masterOrderId,
    Map<String, dynamic> master,
    String providerUid,
  ) {
    final order = MasterOrder.fromMap(masterOrderId, master);
    if (!order.hasProviderSlice(providerUid)) return null;
    final slice = order.sliceFor(providerUid)!;

    return ProviderOrderDashboard(
      id: masterOrderId,
      status: _mapOrderStatus(slice.statusWire),
      statusWire: slice.statusWire,
      createdAt: slice.createdAt,
      acceptedAt: slice.acceptedAt,
      deliveredAt: slice.deliveredAt,
      totalEgp: slice.totalEgp,
      customerName: slice.customerName,
      items: [
        for (final item in slice.items)
          ProviderOrderLineItem(
            itemId: item.itemId,
            name: item.name,
            quantity: item.quantity,
            lineTotalEgp: item.lineTotalEgp,
          ),
      ],
    );
  }

  static OrderStatus _mapOrderStatus(String wire) {
    switch (wire) {
      case 'preparing':
      case 'ready':
      case 'ready_for_pickup':
        return OrderStatus.accepted;
      default:
        return OrderStatus.fromWire(wire);
    }
  }

}
