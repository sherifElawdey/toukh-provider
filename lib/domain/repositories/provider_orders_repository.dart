import 'package:toukh_ui/toukh_ui.dart';

abstract class ProviderOrdersRepository {
  Stream<List<MasterOrder>> watchOrders(String providerUid);

  Future<MasterOrder?> getOrderById({
    required String providerId,
    required String orderId,
  });

  Future<void> approveOrder({
    required String providerId,
    required String orderId,
    required bool storeDelivers,
  });

  Future<void> cancelOrder({
    required String providerId,
    required String orderId,
    String? reason,
  });

  /// Creates a delivery request and sets slice status to [courier_requested].
  Future<String> requestDelivery({
    required String providerId,
    required String orderId,
    required Location searchCenter,
    int radiusMeters = 1000,
  });

  Future<void> markReadyForPickup({
    required String providerId,
    required String orderId,
  });

  Future<void> markStoreOutForDelivery({
    required String providerId,
    required String orderId,
  });

  Future<void> confirmHandoffToCourier({
    required String providerId,
    required String orderId,
  });

  Future<void> approvePharmacyRequest({
    required String providerId,
    required String masterOrderId,
    required String pharmacistNote,
    required List<String> approvedItemIds,
    required double quotedSubtotalEgp,
    required double quotedDeliveryFeeEgp,
  });
}
