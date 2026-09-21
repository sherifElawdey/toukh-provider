/// Notification type strings for home service request lifecycle events.
abstract final class ToukhHomeServiceNotificationTypes {
  ToukhHomeServiceNotificationTypes._();

  static const homeServiceRequestPlaced = 'home_service_request_placed';
  static const homeServiceQuoteReceived = 'home_service_quote_received';
  static const homeServiceRequestAccepted = 'home_service_request_accepted';
  static const homeServiceProviderEnRoute = 'home_service_provider_en_route';
}
