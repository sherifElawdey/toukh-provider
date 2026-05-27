import 'package:toukh_provider/domain/entities/provider_order.dart';
import 'package:toukh_ui/toukh_ui.dart';

abstract class ProviderOrdersRepository {
  Stream<List<ProviderOrder>> watchOrders(String providerUid);

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

  /// Creates a delivery request and sets order status to [courier_requested].
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
}
