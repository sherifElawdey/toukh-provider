import 'package:toukh_ui/toukh_ui.dart';

abstract class NotificationInboxRepository {
  /// Newest [limit] notifications, live.
  Stream<List<ToukhNotification>> watchInbox(String uid, {int limit = 100});

  /// Live unread count (capped at [cap]) for badges, independent of the
  /// loaded page window.
  Stream<int> watchUnreadCount(String uid, {int cap = 99});

  Future<void> markOpened({
    required String uid,
    required String notificationId,
  });

  Future<void> deleteNotification({
    required String uid,
    required String notificationId,
  });

  Future<void> markAllOpened({required String uid});

  Future<void> clearInbox({required String uid});

  Future<int> unreadCount(String uid);
}
