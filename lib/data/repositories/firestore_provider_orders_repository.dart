import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/data/mappers/provider_order_mapper.dart';
import 'package:toukh_provider/domain/entities/provider_fulfillment_mode.dart';
import 'package:toukh_provider/domain/entities/provider_order.dart';
import 'package:toukh_provider/domain/entities/provider_order_status_wire.dart';
import 'package:toukh_provider/data/services/customer_order_notify_service.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderOrdersRepository implements ProviderOrdersRepository {
  FirestoreProviderOrdersRepository(
    this._firestore, {
    CustomerOrderNotifyService? customerNotify,
  }) : _customerNotify = customerNotify;

  final FirebaseFirestore _firestore;
  final CustomerOrderNotifyService? _customerNotify;

  Future<void> _notifyCustomer(String providerId, String orderId) async {
    await _customerNotify?.notifyCustomer(
      providerId: providerId,
      orderId: orderId,
    );
  }

  static const deliveryRequestsCollection = 'deliveryRequests';

  CollectionReference<Map<String, dynamic>> _ordersCol(String providerUid) =>
      _firestore
          .collection(AppConstants.providersCollection)
          .doc(providerUid)
          .collection('orders');

  @override
  Stream<List<ProviderOrder>> watchOrders(String providerUid) {
    return _ordersCol(providerUid)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProviderOrderMapper.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  DocumentReference<Map<String, dynamic>> _orderRef(
    String providerId,
    String orderId,
  ) =>
      _ordersCol(providerId).doc(orderId);

  @override
  Future<void> approveOrder({
    required String providerId,
    required String orderId,
    required bool storeDelivers,
  }) async {
    await _orderRef(providerId, orderId).update({
      'status': ProviderOrderStatusWire.preparing,
      'providerState': 'preparing',
      'fulfillmentMode': storeDelivers
          ? ProviderFulfillmentMode.store.wireValue
          : ProviderFulfillmentMode.courier.wireValue,
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> cancelOrder({
    required String providerId,
    required String orderId,
    String? reason,
  }) async {
    final cancelReason = reason ?? 'unavailable';
    await _orderRef(providerId, orderId).update({
      'status': ProviderOrderStatusWire.cancelled,
      'providerState': 'rejected',
      'cancelReason': cancelReason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _syncCancelledProviderToMaster(
      providerId: providerId,
      orderId: orderId,
      cancelReason: cancelReason,
    );
    await _notifyCustomer(providerId, orderId);
  }

  /// Client fallback when Cloud Functions are not deployed.
  Future<void> _syncCancelledProviderToMaster({
    required String providerId,
    required String orderId,
    required String cancelReason,
  }) async {
    try {
      final orderSnap = await _orderRef(providerId, orderId).get();
      final masterOrderId = orderSnap.data()?['masterOrderId'] as String?;
      if (masterOrderId == null || masterOrderId.isEmpty) return;

      final masterRef = _firestore.collection('masterOrders').doc(masterOrderId);
      String? providerName;
      String? timelineId;

      await _firestore.runTransaction((tx) async {
        final masterSnap = await tx.get(masterRef);
        if (!masterSnap.exists) return;

        final master = masterSnap.data()!;
        timelineId = master['timelineId'] as String? ?? masterOrderId;
        final statusMap = Map<String, dynamic>.from(
          master['providerStatusMap'] as Map? ?? {},
        );
        statusMap[providerId] = 'rejected';

        final refsRaw = master['providerOrderRefs'] as List? ?? [];
        final refs = refsRaw.map((e) {
          final ref = Map<String, dynamic>.from(e as Map);
          if (ref['providerId'] == providerId) {
            ref['providerOrderId'] = orderId;
            ref['providerState'] = 'rejected';
            ref['cancelledAt'] = FieldValue.serverTimestamp();
            ref['cancelReason'] = cancelReason;
            providerName = ref['providerName'] as String? ?? providerId;
          }
          return ref;
        }).toList();

        final updates = <String, dynamic>{
          'providerStatusMap': statusMap,
          'providerOrderRefs': refs,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        final allRejected =
            statusMap.values.isNotEmpty &&
            statusMap.values.every((s) => s == 'rejected');
        if (allRejected) {
          updates['globalStatus'] = 'cancelled';
        }

        tx.update(masterRef, updates);
      });

      final resolvedTimelineId = timelineId ?? masterOrderId;
      await _firestore
          .collection('orderTimelines')
          .doc(resolvedTimelineId)
          .collection('events')
          .add({
        'masterOrderId': masterOrderId,
        'type': 'provider_cancelled',
        'at': FieldValue.serverTimestamp(),
        'actorRole': 'provider',
        'actorId': providerId,
        'payload': {
          'providerName': providerName ?? providerId,
          'cancelReason': cancelReason,
        },
      });
    } catch (_) {
      // CF may handle sync when deployed; ignore duplicate updates.
    }
  }

  @override
  Future<String> requestDelivery({
    required String providerId,
    required String orderId,
    required Location searchCenter,
    int radiusMeters = 1000,
  }) async {
    final requestRef =
        _firestore.collection(deliveryRequestsCollection).doc();
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(_orderRef(providerId, orderId));
      if (!orderSnap.exists) {
        throw StateError('Order not found');
      }

      final masterOrderId = orderSnap.data()?['masterOrderId'] as String?;
      final deliveryTaskId = orderSnap.data()?['deliveryTaskId'] as String?;

      tx.set(requestRef, {
        'providerId': providerId,
        'orderId': orderId,
        if (masterOrderId != null) 'masterOrderId': masterOrderId,
        if (deliveryTaskId != null) 'deliveryTaskId': deliveryTaskId,
        'storeLocation': GeoPoint(searchCenter.lat, searchCenter.lng),
        'searchCenter': ProviderOrderMapper.storeLocationToFirestore(searchCenter),
        'radiusMeters': radiusMeters,
        'status': 'open',
        'candidateDriverIds': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      tx.update(_orderRef(providerId, orderId), {
        'status': ProviderOrderStatusWire.courierRequested,
        'deliveryRequestId': requestRef.id,
        'storeLocation': ProviderOrderMapper.storeLocationToFirestore(searchCenter),
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
    await _orderRef(providerId, orderId).update({
      'status': ProviderOrderStatusWire.readyForPickup,
      'readyForPickupAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> markStoreOutForDelivery({
    required String providerId,
    required String orderId,
  }) async {
    await _orderRef(providerId, orderId).update({
      'status': ProviderOrderStatusWire.outForDelivery,
      'dispatchedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifyCustomer(providerId, orderId);
  }

  @override
  Future<void> confirmHandoffToCourier({
    required String providerId,
    required String orderId,
  }) async {
    await _orderRef(providerId, orderId).update({
      'status': ProviderOrderStatusWire.outForDelivery,
      'dispatchedAt': FieldValue.serverTimestamp(),
      'handedToCourierAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _notifyCustomer(providerId, orderId);
  }
}
