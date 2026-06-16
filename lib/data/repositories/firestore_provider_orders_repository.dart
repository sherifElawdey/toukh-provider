import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/data/services/customer_order_notify_service.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderOrdersRepository implements ProviderOrdersRepository {
  FirestoreProviderOrdersRepository(
    this._firestore, {
    CustomerOrderNotifyService? customerNotify,
    FirebaseFunctions? functions,
  })  : _customerNotify = customerNotify,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final CustomerOrderNotifyService? _customerNotify;
  final FirebaseFunctions? _functions;

  static const deliveryRequestsCollection = 'deliveryRequests';
  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _notifyCustomer(String providerId, String masterOrderId) async {
    await _customerNotify?.notifyCustomer(
      providerId: providerId,
      orderId: masterOrderId,
    );
  }

  DocumentReference<Map<String, dynamic>> _masterRef(String masterOrderId) =>
      _firestore.collection(ToukhOrderPaths.masterOrders).doc(masterOrderId);

  static bool _hasProviderSlice(MasterOrder m, String providerUid) =>
      m.hasProviderSlice(providerUid);

  static void _sortActive(List<MasterOrder> orders) {
    orders.sort((a, b) {
      final at = a.createdAt ?? _epoch;
      final bt = b.createdAt ?? _epoch;
      return bt.compareTo(at);
    });
  }

  static void _sortFinished(List<MasterOrder> orders) {
    orders.sort((a, b) {
      final at = a.providerSlices.values
              .map((s) => s.deliveredAt ?? s.createdAt)
              .whereType<DateTime>()
              .fold<DateTime?>(null, (prev, d) {
            if (prev == null) return d;
            return d.isAfter(prev) ? d : prev;
          }) ??
          a.createdAt ??
          _epoch;
      final bt = b.providerSlices.values
              .map((s) => s.deliveredAt ?? s.createdAt)
              .whereType<DateTime>()
              .fold<DateTime?>(null, (prev, d) {
            if (prev == null) return d;
            return d.isAfter(prev) ? d : prev;
          }) ??
          b.createdAt ??
          _epoch;
      return bt.compareTo(at);
    });
  }

  @override
  Stream<List<MasterOrder>> watchOrders(String providerUid) {
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? activeSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? finishedSub;

    late StreamController<List<MasterOrder>> controller;

    List<MasterOrder> active = [];
    List<MasterOrder> finished = [];

    void emit() {
      if (!controller.isClosed) {
        final merged = <String, MasterOrder>{
          for (final m in active) m.id: m,
          for (final m in finished) m.id: m,
        };
        final list = merged.values.toList();
        _sortActive(list);
        controller.add(list);
      }
    }

    controller = StreamController<List<MasterOrder>>(
      onListen: () {
        activeSub = _firestore
            .collection(ToukhOrderPaths.masterOrders)
            .where('providerIds', arrayContains: providerUid)
            .limit(200)
            .snapshots()
            .listen(
              (snap) {
                active = snap.docs
                    .map((d) => MasterOrder.fromMap(d.id, d.data()))
                    .where((m) => _hasProviderSlice(m, providerUid))
                    .toList();
                _sortActive(active);
                emit();
              },
              onError: controller.addError,
            );

        finishedSub = _firestore
            .collection(ToukhOrderPaths.finishedOrders)
            .where('providerIds', arrayContains: providerUid)
            .limit(200)
            .snapshots()
            .listen(
              (snap) {
                finished = snap.docs
                    .map((d) => FinishedOrder.fromMap(d.id, d.data()).order)
                    .where((m) => _hasProviderSlice(m, providerUid))
                    .toList();
                _sortFinished(finished);
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
  Future<MasterOrder?> getOrderById({
    required String providerId,
    required String orderId,
  }) async {
    final masterSnap = await _masterRef(orderId).get();
    if (masterSnap.exists && masterSnap.data() != null) {
      final order = MasterOrder.fromMap(orderId, masterSnap.data()!);
      if (_hasProviderSlice(order, providerId)) return order;
    }

    final finishedSnap = await _firestore
        .collection(ToukhOrderPaths.finishedOrders)
        .doc(orderId)
        .get();
    if (finishedSnap.exists && finishedSnap.data() != null) {
      final order = FinishedOrder.fromMap(orderId, finishedSnap.data()!).order;
      if (_hasProviderSlice(order, providerId)) return order;
    }

    return null;
  }

  Future<void> _patchSlice({
    required String providerId,
    required String masterOrderId,
    required Map<String, dynamic> patch,
  }) async {
    final functions = _functions;
    if (functions != null) {
      try {
        await functions.httpsCallable('updateProviderOrderSlice').call({
          'masterOrderId': masterOrderId,
          'providerId': providerId,
          'patch': patch,
        });
        return;
      } on FirebaseFunctionsException catch (e) {
        if (e.code != 'not-found' && e.code != 'unavailable') {
          if (kDebugMode) {
            debugPrint('updateProviderOrderSlice failed: ${e.code} ${e.message}');
          }
          rethrow;
        }
      }
    }
    await _patchSliceFallback(
      providerId: providerId,
      masterOrderId: masterOrderId,
      patch: patch,
    );
  }

  Future<void> _patchSliceFallback({
    required String providerId,
    required String masterOrderId,
    required Map<String, dynamic> patch,
  }) async {
    final masterRef = _masterRef(masterOrderId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(masterRef);
      if (!snap.exists) throw StateError('Order not found');

      final master = snap.data()!;
      final slices = Map<String, dynamic>.from(
        master['providerSlices'] as Map? ?? {},
      );
      final slice = Map<String, dynamic>.from(
        slices[providerId] as Map? ?? {},
      );
      if (slice.isEmpty) throw StateError('Provider slice not found');

      slice.addAll(patch);
      slice['updatedAt'] = FieldValue.serverTimestamp();
      slices[providerId] = slice;

      final statusMap = Map<String, dynamic>.from(
        master['providerStatusMap'] as Map? ?? {},
      );
      if (patch['providerState'] != null) {
        statusMap[providerId] = patch['providerState'];
      } else if (patch['status'] != null) {
        statusMap[providerId] = _mapWireToProviderState(patch['status'] as String);
      }

      final status = patch['status'] as String?;
      final refsRaw = master['providerOrderRefs'] as List? ?? [];
      final refs = refsRaw.map((e) {
        final ref = Map<String, dynamic>.from(e as Map);
        if (ref['providerId'] == providerId) {
          ref['providerState'] = statusMap[providerId] ?? ref['providerState'];
          if (status == 'cancelled') {
            if (slice['cancelledAt'] != null) {
              ref['cancelledAt'] = slice['cancelledAt'];
            }
            if (slice['cancelReason'] != null) {
              ref['cancelReason'] = slice['cancelReason'];
            }
            ref['cancelledByRole'] =
                slice['cancelledByRole'] as String? ?? 'provider';
          }
        }
        return ref;
      }).toList();

      final updates = <String, dynamic>{
        'providerSlices': slices,
        'providerStatusMap': statusMap,
        'providerOrderRefs': refs,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'out_for_delivery') updates['globalStatus'] = 'on_the_way';
      if (status == 'delivered' || status == 'completed') {
        updates['globalStatus'] = 'delivered';
      }
      if (status == 'cancelled') {
        final allCancelled = statusMap.values.isNotEmpty &&
            statusMap.values.every((s) => s == 'rejected');
        if (allCancelled) updates['globalStatus'] = 'cancelled';
      }

      tx.update(masterRef, updates);
    });
  }

  String _mapWireToProviderState(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
      case 'pending':
        return 'pending';
      case 'accepted':
      case 'preparing':
        return 'preparing';
      case 'ready_for_pickup':
        return 'ready_for_pickup';
      case 'picked_up':
      case 'out_for_delivery':
        return 'picked_up';
      case 'delivered':
      case 'completed':
        return 'picked_up';
      case 'cancelled':
        return 'rejected';
      default:
        return 'pending';
    }
  }

  @override
  Future<void> approveOrder({
    required String providerId,
    required String orderId,
    required bool storeDelivers,
  }) async {
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: {
        'status': ProviderOrderStatusWire.preparing,
        'providerState': 'preparing',
        'fulfillmentMode': storeDelivers
            ? FulfillmentMode.store.wireValue
            : FulfillmentMode.courier.wireValue,
        'acceptedAt': FieldValue.serverTimestamp(),
      },
    );
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> cancelOrder({
    required String providerId,
    required String orderId,
    String? reason,
  }) async {
    final cancelReason = reason ?? 'unavailable';
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: {
        'status': ProviderOrderStatusWire.cancelled,
        'providerState': 'rejected',
        'cancelReason': cancelReason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledByRole': 'provider',
      },
    );
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<String> requestDelivery({
    required String providerId,
    required String orderId,
    required Location searchCenter,
    int radiusMeters = 1000,
  }) async {
    final requestRef = _firestore.collection(deliveryRequestsCollection).doc();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    String? deliveryTaskId;

    await _firestore.runTransaction((tx) async {
      final masterSnap = await tx.get(_masterRef(orderId));
      if (!masterSnap.exists) throw StateError('Order not found');

      final master = masterSnap.data()!;
      final slices = Map<String, dynamic>.from(
        master['providerSlices'] as Map? ?? {},
      );
      final slice = Map<String, dynamic>.from(
        slices[providerId] as Map? ?? {},
      );
      deliveryTaskId = slice['deliveryTaskId'] as String?;

      tx.set(requestRef, {
        'providerId': providerId,
        'orderId': orderId,
        'masterOrderId': orderId,
        if (deliveryTaskId != null) 'deliveryTaskId': deliveryTaskId,
        'storeLocation': GeoPoint(searchCenter.lat, searchCenter.lng),
        'searchCenter': _locationToMap(searchCenter),
        'radiusMeters': radiusMeters,
        'status': 'open',
        'candidateDriverIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      slice['status'] = ProviderOrderStatusWire.courierRequested;
      slice['deliveryRequestId'] = requestRef.id;
      slice['storeLocation'] = _locationToMap(searchCenter);
      slice['updatedAt'] = FieldValue.serverTimestamp();
      slices[providerId] = slice;

      tx.update(_masterRef(orderId), {
        'providerSlices': slices,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _notifyCustomer(providerId, orderId);
    return requestRef.id;
  }

  @override
  Future<void> markReadyForPickup({
    required String providerId,
    required String orderId,
  }) async {
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: {
        'status': ProviderOrderStatusWire.readyForPickup,
        'readyForPickupAt': FieldValue.serverTimestamp(),
      },
    );
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> markStoreOutForDelivery({
    required String providerId,
    required String orderId,
  }) async {
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: {
        'status': ProviderOrderStatusWire.outForDelivery,
        'dispatchedAt': FieldValue.serverTimestamp(),
      },
    );
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> confirmHandoffToCourier({
    required String providerId,
    required String orderId,
  }) async {
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: {
        'status': ProviderOrderStatusWire.outForDelivery,
        'dispatchedAt': FieldValue.serverTimestamp(),
        'handedToCourierAt': FieldValue.serverTimestamp(),
      },
    );
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> approvePharmacyRequest({
    required String providerId,
    required String masterOrderId,
    required String pharmacistNote,
    required List<String> approvedItemIds,
    required double quotedSubtotalEgp,
    required double quotedDeliveryFeeEgp,
  }) async {
    final fn = _functions;
    if (fn == null) {
      throw StateError('Cloud Functions not configured');
    }
    final callable = fn.httpsCallable('approvePharmacyRequest');
    await callable.call<Map<String, dynamic>>({
      'masterOrderId': masterOrderId,
      'providerId': providerId,
      'pharmacistNote': pharmacistNote,
      'approvedItemIds': approvedItemIds,
      'quotedSubtotalEgp': quotedSubtotalEgp,
      'quotedDeliveryFeeEgp': quotedDeliveryFeeEgp,
    });
  }

  Map<String, dynamic> _locationToMap(Location loc) => {
        'lat': loc.lat,
        'lng': loc.lng,
        if (loc.label != null) 'label': loc.label,
        if (loc.formattedAddress != null) 'formattedAddress': loc.formattedAddress,
      };
}
