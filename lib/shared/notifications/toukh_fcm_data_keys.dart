/// FCM data payload keys (all values must be strings on the wire).
abstract final class ToukhFcmDataKeys {
  ToukhFcmDataKeys._();

  static const notificationId = 'notificationId';
  static const rootRoute = 'rootRoute';
  static const payloadJson = 'payloadJson';
  static const imageUrl = 'imageUrl';
  static const link = 'link';
  static const type = 'type';
  static const orderId = 'orderId';
  static const requestId = 'requestId';
  static const visitDate = 'visitDate';
  static const category = 'category';
}
