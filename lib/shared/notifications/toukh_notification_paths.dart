import 'toukh_notification_recipient.dart';

/// Firestore path helpers for notification inboxes.
abstract final class ToukhNotificationPaths {
  ToukhNotificationPaths._();

  static const notificationsSubcollection = 'notifications';

  /// Parent document path: `users/{uid}`, `providers/{uid}`, or `drivers/{uid}`.
  static String recipientDocPath({
    required ToukhNotificationRecipient recipient,
    required String uid,
  }) {
    return '${recipient.collectionName}/$uid';
  }

  /// Subcollection path segment under the recipient doc.
  static String inboxCollectionPath({
    required ToukhNotificationRecipient recipient,
    required String uid,
  }) {
    return '${recipientDocPath(recipient: recipient, uid: uid)}/$notificationsSubcollection';
  }
}
