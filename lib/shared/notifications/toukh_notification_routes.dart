/// In-app navigation targets for notification deep links (GoRouter paths).
abstract final class ToukhNotificationRoutes {
  ToukhNotificationRoutes._();

  // Consumer (toukh)
  static const consumerOrders = '/orders';
  static const consumerNotifications = '/notifications';

  static String consumerOrderDetail(String masterOrderId) =>
      '/orders/$masterOrderId';

  static const consumerHomeServiceRequestDetail = '/home-service-request-detail';

  // Provider (toukh_provider)
  static const providerOrders = '/orders';
  static const providerNotifications = '/notifications';

  static String providerOrderDetail(String orderId) => '$providerOrders/$orderId';

  static String providerHomeServiceRequestDetail(String requestId) =>
      '/home-service-request/$requestId';

  // Driver (toukh_delivery)
  static const driverOrders = '/orders';
  static const driverNotifications = '/notifications';

  static String driverOrderDetail(String orderId) =>
      '$driverOrders/detail/${Uri.encodeComponent(orderId)}';
}
