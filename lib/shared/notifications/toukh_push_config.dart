/// Shared FCM / local notification display configuration.
abstract final class ToukhPushConfig {
  ToukhPushConfig._();

  static const androidChannelId = 'toukh_notifications';
  static const androidChannelName = 'إشعارات طوخ';
  static const androidChannelDescription = 'تحديثات الطلبات والتنبيهات';

  static const visitReminderChannelId = 'toukh_visit_reminders';
  static const visitReminderChannelName = 'تذكيرات الزيارة';
  static const visitReminderChannelDescription =
      'تذكيرات زيارات الخدمات المنزلية المجدولة';

  /// Android launcher icon resource name (without @mipmap/).
  static const androidIcon = 'ic_launcher';
}
