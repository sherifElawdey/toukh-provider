import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/shared/shared.dart';
import 'package:toukh_provider/domain/entities/dashboard_firestore_payload.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/data/mappers/provider_review_mapper.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';

class FirestoreProviderDashboardRepository implements ProviderDashboardRepository {
  FirestoreProviderDashboardRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviewsCol(String providerUid) =>
      _firestore.collection(ToukhFirestoreCollections.providers).doc(providerUid).collection(ToukhFirestoreCollections.reviews);

  @override
  Stream<DashboardFirestorePayload> watchFirestorePayload(String providerUid) {
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? activeSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? finishedSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? hsSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? reviewsSub;

    late StreamController<DashboardFirestorePayload> controller;

    List<ProviderOrderDashboard> marketplaceOrders = [];
    List<ProviderOrderDashboard> homeServiceOrders = [];
    List<ProviderReviewSummary> reviews = [];

    void emitMerged() {
      if (controller.isClosed) return;
      final merged = [...marketplaceOrders, ...homeServiceOrders]
        ..sort((a, b) {
          final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
      controller.add(
        DashboardFirestorePayload(
          orders: List.unmodifiable(merged),
          reviews: List.unmodifiable(reviews),
        ),
      );
    }

    controller = StreamController<DashboardFirestorePayload>(
      onListen: () {
        final activeOrders = <ProviderOrderDashboard>[];
        final finishedOrders = <ProviderOrderDashboard>[];

        void emitMarketplace() {
          marketplaceOrders = [...activeOrders, ...finishedOrders];
          emitMerged();
        }

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
                emitMarketplace();
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
                  final at = a.deliveredAt ??
                      a.createdAt ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = b.deliveredAt ??
                      b.createdAt ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
                emitMarketplace();
              },
              onError: controller.addError,
            );

        hsSub = _firestore
            .collection(ToukhFirestoreCollections.homeServiceRequests)
            .where('providerId', isEqualTo: providerUid)
            .limit(500)
            .snapshots()
            .listen(
              (snap) {
                homeServiceOrders = snap.docs
                    .map((d) => _mapFromHomeService(d.id, d.data()))
                    .whereType<ProviderOrderDashboard>()
                    .toList();
                emitMerged();
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
                emitMerged();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await activeSub?.cancel();
        await finishedSub?.cancel();
        await hsSub?.cancel();
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
    final orderPrice = slice.orderPriceEgp > 0
        ? slice.orderPriceEgp
        : slice.totalEgp;

    return ProviderOrderDashboard(
      id: masterOrderId,
      status: _mapOrderStatus(slice.statusWire),
      statusWire: slice.statusWire,
      createdAt: slice.createdAt,
      acceptedAt: slice.acceptedAt,
      deliveredAt: slice.deliveredAt,
      totalEgp: slice.totalEgp,
      orderPriceEgp: orderPrice,
      customerName: providerCanViewCustomerContact(order, slice)
          ? (slice.customerName ?? order.customerName)
          : null,
      hideCustomerContact: order.isPharmacyRequest &&
          !providerCanViewCustomerContact(order, slice),
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

  static ProviderOrderDashboard? _mapFromHomeService(
    String requestId,
    Map<String, dynamic> data,
  ) {
    final statusWire =
        (data['status'] as String? ?? '').trim().toLowerCase();
    if (statusWire.isEmpty) return null;

    final quoted = _toDouble(data['quotedPriceEgp']);
    final client = _toDouble(data['clientPriceEgp']);
    final price = (quoted != null && quoted > 0)
        ? quoted
        : (client != null && client > 0 ? client : 0.0);

    final createdAt = ToukhFirestoreTimestamps.toDateTime(data['createdAt']);
    final completedAt = ToukhFirestoreTimestamps.toDateTime(data['completedAt']);
    final cancelledAt = ToukhFirestoreTimestamps.toDateTime(data['cancelledAt']);
    final scheduledAt = ToukhFirestoreTimestamps.toDateTime(data['scheduledAt']);
    final onMyWayAt = ToukhFirestoreTimestamps.toDateTime(data['onMyWayAt']);

    final acceptedAt = scheduledAt ??
        onMyWayAt ??
        (statusWire == 'accepted' ||
                statusWire == 'in_progress' ||
                statusWire == 'completed'
            ? createdAt
            : null);

    return ProviderOrderDashboard(
      id: requestId,
      status: _mapHomeServiceStatus(statusWire),
      statusWire: statusWire,
      createdAt: createdAt,
      acceptedAt: acceptedAt,
      deliveredAt: completedAt ?? cancelledAt,
      totalEgp: price,
      orderPriceEgp: price,
      customerName: (data['customerName'] as String?)?.trim(),
      items: const [],
      isHomeService: true,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) {
      return double.tryParse(v.trim());
    }
    return null;
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

  static OrderStatus _mapHomeServiceStatus(String wire) {
    switch (wire) {
      case 'completed':
        return OrderStatus.delivered;
      case 'cancelled':
      case 'rejected':
      case 'declined':
        return OrderStatus.cancelled;
      case 'accepted':
      case 'in_progress':
        return OrderStatus.accepted;
      case 'pending':
      case 'tendering':
      case 'quoted':
      case 'awaiting_customer':
      case 'awaiting_provider':
        return OrderStatus.placed;
      default:
        return OrderStatus.fromWire(wire);
    }
  }
}
