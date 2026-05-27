import 'package:toukh_ui/toukh_ui.dart';

abstract class NotificationInboxRepository {
  Stream<List<ToukhNotification>> watchInbox(String uid);

  Future<void> markOpened({required String uid, required String notificationId});

  Future<int> unreadCount(String uid);
}
