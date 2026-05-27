import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/domain/entities/provider_fulfillment_mode.dart';
import 'package:toukh_provider/domain/entities/provider_order_status_wire.dart';

/// Manual Firestore seed shape for testing provider orders UI.
///
/// Path: `providers/{providerUid}/orders/{orderId}`
///
/// Example document:
/// ```json
/// {
///   "status": "placed",
///   "fulfillmentMode": "courier",
///   "customerName": "Test Customer",
///   "customerPhone": "01000000000",
///   "orderPrice": 120,
///   "deliveryPrice": 25,
///   "totalEgp": 145,
///   "createdAt": "<Timestamp>",
///   "items": [{"name": "Burger", "quantity": 2, "lineTotalEgp": 120}],
///   "storeLocation": {"lat": 30.0444, "lng": 31.2357, "label": "Store"},
///   "deliveryAddress": {"lat": 30.05, "lng": 31.24, "formattedAddress": "Customer"}
/// }
/// ```
abstract final class ProviderOrderSeed {
  ProviderOrderSeed._();

  static Future<String> createPlacedOrder({
    required FirebaseFirestore firestore,
    required String providerUid,
    bool storeDelivers = false,
  }) async {
    final ref = firestore
        .collection(AppConstants.providersCollection)
        .doc(providerUid)
        .collection('orders')
        .doc();

    await ref.set({
      'status': ProviderOrderStatusWire.placed,
      'fulfillmentMode': storeDelivers
          ? ProviderFulfillmentMode.store.wireValue
          : ProviderFulfillmentMode.courier.wireValue,
      'customerName': 'Test Customer',
      'customerPhone': '01000000000',
      'orderPrice': 120.0,
      'deliveryPrice': storeDelivers ? 0.0 : 25.0,
      'totalEgp': storeDelivers ? 120.0 : 145.0,
      'createdAt': FieldValue.serverTimestamp(),
      'items': [
        {
          'name': 'Test item',
          'quantity': 1,
          'lineTotalEgp': 120.0,
        },
      ],
      'storeLocation': {
        'lat': 30.0444,
        'lng': 31.2357,
        'label': 'Store',
      },
      'deliveryAddress': {
        'lat': 30.05,
        'lng': 31.24,
        'formattedAddress': 'Customer address',
      },
    });

    return ref.id;
  }
}
