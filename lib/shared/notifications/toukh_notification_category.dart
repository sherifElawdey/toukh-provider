/// Notification inbox category strings (stored on Firestore docs + FCM data).
abstract final class ToukhNotificationCategory {
  ToukhNotificationCategory._();

  static const order = 'order';
  static const homeService = 'home_service';
  static const message = 'message';
  static const system = 'system';
  static const support = 'support';
}
