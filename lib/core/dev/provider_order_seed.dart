import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Manual Firestore seed for testing provider orders UI via [masterOrders].
///
/// Path: `masterOrders/{masterOrderId}` with `providerSlices.{providerUid}`.
abstract final class ProviderOrderSeed {
  ProviderOrderSeed._();

  static Future<String> createPlacedOrder({
    required FirebaseFirestore firestore,
    required String providerUid,
    bool storeDelivers = false,
  }) async {
    final ref = firestore.collection(ToukhOrderPaths.masterOrders).doc();
    final placedAt = ToukhFirestoreTimestamps.createdAtNow();

    await ref.set({
      'clientId': 'seed-customer',
      'globalStatus': 'pending',
      'providerIds': [providerUid],
      'providerStatusMap': {providerUid: 'pending'},
      'providerOrderRefs': [
        {
          'providerId': providerUid,
          'providerOrderId': ref.id,
          'providerState': 'pending',
          'fulfillmentMode': storeDelivers ? 'store' : 'courier',
          'orderPriceEgp': 120,
          'deliveryFeeEgp': 25,
        },
      ],
      'providerSlices': {
        providerUid: {
          'status': 'placed',
          'providerState': 'pending',
          'fulfillmentMode': storeDelivers ? 'store' : 'courier',
          'customerName': 'Test Customer',
          'customerPhone': '01000000000',
          'orderPrice': 120,
          'orderPriceEgp': 120,
          'deliveryPrice': 25,
          'deliveryFeeEgp': 25,
          'totalEgp': 145,
          ...ToukhFirestoreTimestamps.orderPlacementFields(createdAt: placedAt),
          'items': [
            {'name': 'Burger', 'quantity': 2, 'lineTotalEgp': 120},
          ],
          'storeLocation': {'lat': 30.0444, 'lng': 31.2357, 'label': 'Store'},
          'deliveryAddress': {
            'lat': 30.05,
            'lng': 31.24,
            'formattedAddress': 'Customer',
          },
        },
      },
      'deliveryAddress': {
        'lat': 30.05,
        'lng': 31.24,
        'formattedAddress': 'Customer',
      },
      ...ToukhFirestoreTimestamps.orderPlacementFields(createdAt: placedAt),
    });

    return ref.id;
  }
}
