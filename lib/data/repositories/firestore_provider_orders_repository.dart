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

  static const deliveryRequestsCollection = ToukhFirestoreCollections.deliveryRequests;
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
    String? completionCode,
  }) async {
    final functions = _functions;
    if (functions != null) {
      try {
        await functions.httpsCallable('updateProviderOrderSlice').call({
          'masterOrderId': masterOrderId,
          'providerId': providerId,
          'patch': patch,
          'completionCode': ?completionCode,
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
      final status = patch['status'] as String?;
      if (status == 'cancelled') {
        slice['cancelledAt'] = FieldValue.serverTimestamp();
        slice['cancelledByRole'] =
            patch['cancelledByRole'] as String? ??
            slice['cancelledByRole'] as String? ??
            'provider';
        if (patch['cancelReason'] != null) {
          slice['cancelReason'] = patch['cancelReason'];
        }
      }
      if (status == 'preparing' || status == 'accepted') {
        slice['acceptedAt'] = FieldValue.serverTimestamp();
      }
      if (status == 'ready_for_pickup') {
        slice['readyForPickupAt'] = FieldValue.serverTimestamp();
      }
      if (status == 'out_for_delivery') {
        slice['dispatchedAt'] = FieldValue.serverTimestamp();
        if (patch['handedToCourier'] == true) {
          slice['handedToCourierAt'] = FieldValue.serverTimestamp();
        }
      }
      if (status == 'delivered' || status == 'completed') {
        slice['deliveredAt'] ??= FieldValue.serverTimestamp();
      }
      slice.remove('handedToCourier');
      slices[providerId] = slice;

      final statusMap = Map<String, dynamic>.from(
        master['providerStatusMap'] as Map? ?? {},
      );
      if (patch['providerState'] != null) {
        statusMap[providerId] = patch['providerState'];
      } else if (patch['status'] != null) {
        statusMap[providerId] = _mapWireToProviderState(patch['status'] as String);
      }

      final refsRaw = master['providerOrderRefs'] as List? ?? [];
      final refs = refsRaw.map((e) {
        final ref = Map<String, dynamic>.from(e as Map);
        if (ref['providerId'] == providerId) {
          ref['providerState'] = statusMap[providerId] ?? ref['providerState'];
          if (status == 'cancelled') {
            // FieldValue.serverTimestamp() is invalid inside array elements.
            ref['cancelledAt'] = Timestamp.now();
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
    final masterSnap = await _masterRef(orderId).get();
    final existingMode = masterSnap.data()?['providerSlices']?[providerId]
        ?['fulfillmentMode'] as String?;
    final patch = <String, dynamic>{
      'status': ProviderOrderStatusWire.preparing,
      'providerState': 'preparing',
      // Scalars only — CF sets slice.acceptedAt via FieldValue.
    };
    if (existingMode != 'pickup') {
      patch['fulfillmentMode'] = storeDelivers
          ? FulfillmentMode.store.wireValue
          : FulfillmentMode.courier.wireValue;
    }
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: patch,
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
    // Scalars only for the callable — CF sets slice.cancelledAt via FieldValue.
    // Never send FieldValue here: it must not be copied into providerOrderRefs[].
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: {
        'status': ProviderOrderStatusWire.cancelled,
        'providerState': 'rejected',
        'cancelReason': cancelReason,
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
  }) async {
    final requestRef = _firestore.collection(deliveryRequestsCollection).doc();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 15));

    late final String resultRequestId;

    await _firestore.runTransaction((tx) async {
      final masterRef = _masterRef(orderId);
      final masterSnap = await tx.get(masterRef);
      if (!masterSnap.exists) throw StateError('Order not found');

      final master = masterSnap.data()!;
      final slices = Map<String, dynamic>.from(
        master['providerSlices'] as Map? ?? {},
      );
      final slice = Map<String, dynamic>.from(
        slices[providerId] as Map? ?? {},
      );
      final deliveryTaskId = slice['deliveryTaskId'] as String? ??
          master['deliveryTaskId'] as String?;

      final existingSearchId =
          (master['driverSearchRequestId'] as String?)?.trim();
      final priorSliceRequestId =
          (slice['deliveryRequestId'] as String?)?.trim();
      final requestedAt = ToukhFirestoreTimestamps.toDateTime(
            master['deliveryRequestedAt'],
          ) ??
          ToukhFirestoreTimestamps.toDateTime(slice['deliveryRequestedAt']);
      final searchExpired = requestedAt == null
          ? true
          : now.toUtc().difference(requestedAt.toUtc()) >=
              const Duration(minutes: 15);
      final hasDriver = (master['driverAssignment'] is Map &&
              ((master['driverAssignment'] as Map)['driverId'] as String?)
                      ?.trim()
                      .isNotEmpty ==
                  true) ||
          (slice['driverId'] as String?)?.trim().isNotEmpty == true;

      if (hasDriver) {
        throw StateError('A driver is already assigned.');
      }

      // Firestore requires every read to finish before any write.
      final providerSnap = await tx.get(
        _firestore
            .collection(ToukhFirestoreCollections.providers)
            .doc(providerId),
      );
      final providerServiceAreaId =
          (providerSnap.data()?['serviceAreaId'] as String?)?.trim();

      DocumentSnapshot<Map<String, dynamic>>? existingSearchSnap;
      if (existingSearchId != null && existingSearchId.isNotEmpty) {
        existingSearchSnap = await tx.get(
          _firestore
              .collection(deliveryRequestsCollection)
              .doc(existingSearchId),
        );
      }

      DocumentSnapshot<Map<String, dynamic>>? priorSliceRequestSnap;
      if (priorSliceRequestId != null &&
          priorSliceRequestId.isNotEmpty &&
          priorSliceRequestId != existingSearchId) {
        priorSliceRequestSnap = await tx.get(
          _firestore
              .collection(deliveryRequestsCollection)
              .doc(priorSliceRequestId),
        );
      }

      // Join an active shared search instead of creating a parallel request.
      if (existingSearchId != null &&
          existingSearchId.isNotEmpty &&
          !searchExpired &&
          existingSearchSnap != null &&
          existingSearchSnap.exists &&
          existingSearchSnap.data()?['status'] == 'open') {
        slice['status'] = ProviderOrderStatusWire.courierRequested;
        slice['deliveryRequestId'] = existingSearchId;
        slice['storeLocation'] = _locationToMap(searchCenter);
        slice['deliveryRequestedAt'] = master['deliveryRequestedAt'] ??
            Timestamp.fromDate(requestedAt);
        slice['updatedAt'] = FieldValue.serverTimestamp();
        slices[providerId] = slice;
        tx.update(masterRef, {
          'providerSlices': slices,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        resultRequestId = existingSearchId;
        return;
      }

      // Expire previous open request on re-request.
      if (existingSearchSnap != null &&
          existingSearchSnap.exists &&
          existingSearchSnap.data()?['status'] == 'open') {
        tx.update(existingSearchSnap.reference, {
          'status': 'expired',
          'candidateDriverIds': <String>[],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (priorSliceRequestSnap != null &&
          priorSliceRequestSnap.exists &&
          priorSliceRequestSnap.data()?['status'] == 'open') {
        tx.update(priorSliceRequestSnap.reference, {
          'status': 'expired',
          'candidateDriverIds': <String>[],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final deliveryAddress = master['deliveryAddress'];

      tx.set(requestRef, {
        'providerId': providerId,
        'orderId': orderId,
        'masterOrderId': orderId,
        'deliveryTaskId': ?deliveryTaskId,
        'storeLocation': GeoPoint(searchCenter.lat, searchCenter.lng),
        'searchCenter': _locationToMap(searchCenter),
        if (deliveryAddress is Map) 'deliveryLocation': deliveryAddress,
        if (providerServiceAreaId != null && providerServiceAreaId.isNotEmpty)
          'serviceAreaId': providerServiceAreaId,
        'status': 'open',
        'candidateDriverIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      slice['status'] = ProviderOrderStatusWire.courierRequested;
      slice['deliveryRequestId'] = requestRef.id;
      slice['storeLocation'] = _locationToMap(searchCenter);
      slice['deliveryRequestedAt'] = FieldValue.serverTimestamp();
      slice['updatedAt'] = FieldValue.serverTimestamp();
      slices[providerId] = slice;

      tx.update(masterRef, {
        'providerSlices': slices,
        'globalStatus': 'searching_driver',
        'driverSearchRequestId': requestRef.id,
        'deliveryRequestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      resultRequestId = requestRef.id;
    });

    await _notifyCustomer(providerId, orderId);
    return resultRequestId;
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
        // CF sets readyForPickupAt on the slice map.
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
        // CF sets dispatchedAt on the slice map.
      },
    );
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> assignStoreDriverAndDispatch({
    required String providerId,
    required String orderId,
    required String driverId,
    required String driverName,
    String? driverPhotoUrl,
  }) async {
    // Soft assign only — slice stays preparing/accepted (inProgress) until the
    // linked driver accepts via acknowledgeStoreAssignment.
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: {
        'driverId': driverId,
        'driverName': driverName,
        if (driverPhotoUrl != null && driverPhotoUrl.trim().isNotEmpty)
          'driverPhotoUrl': driverPhotoUrl.trim(),
      },
    );
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
        'handedToCourier': true,
        // CF sets dispatchedAt + handedToCourierAt on the slice map.
      },
    );
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> markDelivered({
    required String providerId,
    required String orderId,
    required String completionCode,
  }) async {
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: {
        'status': ProviderOrderStatusWire.delivered,
        'providerState': 'picked_up',
      },
      completionCode: completionCode,
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
