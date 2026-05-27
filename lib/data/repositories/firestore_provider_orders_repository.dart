import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/data/mappers/provider_order_mapper.dart';
import 'package:toukh_provider/domain/entities/provider_fulfillment_mode.dart';
import 'package:toukh_provider/domain/entities/provider_order.dart';
import 'package:toukh_provider/domain/entities/provider_order_status_wire.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderOrdersRepository implements ProviderOrdersRepository {
  FirestoreProviderOrdersRepository(this._firestore);

  final FirebaseFirestore _firestore;

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
  }

  @override
  Future<void> cancelOrder({
    required String providerId,
    required String orderId,
    String? reason,
  }) async {
    await _orderRef(providerId, orderId).update({
      'status': ProviderOrderStatusWire.cancelled,
      'providerState': 'rejected',
      'cancelReason': reason ?? 'unavailable',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
  }
}
