import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderOrdersRepository implements ProviderOrdersRepository {
  FirestoreProviderOrdersRepository(
    this._firestore, {
    FirebaseFunctions? functions,
  }) : _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functions;

  static const deliveryRequestsCollection = ToukhFirestoreCollections.deliveryRequests;
  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

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
    if (functions == null) {
      throw StateError('Cloud Functions not configured');
    }
    try {
      await functions.httpsCallable('updateProviderOrderSlice').call({
        'masterOrderId': masterOrderId,
        'providerId': providerId,
        'patch': patch,
        'completionCode': ?completionCode,
      });
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        debugPrint('updateProviderOrderSlice failed: ${e.code} ${e.message}');
      }
      rethrow;
    }
  }


  @override
  Future<void> approveOrder({
    required String providerId,
    required String orderId,
    required bool storeDelivers,
    required bool selfManagedDelivery,
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
      patch['selfManagedDelivery'] = selfManagedDelivery;
    } else {
      patch['selfManagedDelivery'] = false;
    }
    await _patchSlice(
      providerId: providerId,
      masterOrderId: orderId,
      patch: patch,
    );
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
  }

  @override
  Future<String> requestDelivery({
    required String providerId,
    required String orderId,
    required Location searchCenter,
  }) async {
    final requestRef = _firestore.collection(deliveryRequestsCollection).doc();
    final now = DateTime.now();
    // Admin-set wait (dispatchSettings); the cubit keeps this current.
    final searchWindow = DriverSearchWindow.current;
    final expiresAt = now.add(searchWindow);

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
          : now.toUtc().difference(requestedAt.toUtc()) >= searchWindow;
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
      final deliveryFeeEgp = (master['deliveryFeeEgp'] as num?)?.toDouble() ??
          (master['route'] is Map
              ? ((master['route'] as Map)['deliveryFee'] as num?)?.toDouble()
              : null) ??
          0.0;

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
        'estimatedEarnings': deliveryFeeEgp,
        'deliveryFeeEgp': deliveryFeeEgp,
        'customerName': master['customerName'],
        'customerPhone': master['customerPhone'],
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
        // Overall status is server-derived from every store's slice.
        'driverSearchRequestId': requestRef.id,
        'deliveryRequestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      resultRequestId = requestRef.id;
    });
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
