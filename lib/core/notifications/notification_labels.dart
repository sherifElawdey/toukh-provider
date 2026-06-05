import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Localized labels for notification list styling.
abstract final class NotificationLabels {
  NotificationLabels._();

  static String? statusChipLabel(ToukhNotification notification) {
    final chipKey =
        ToukhNotificationStyleResolver.resolve(notification).statusChipKey;
    if (chipKey == null) return null;
    return switch (chipKey) {
      'placed' => AppStrings.Notifications.statusPlaced.tr,
      'preparing' => AppStrings.Notifications.statusPreparing.tr,
      'driver_assigned' => AppStrings.Notifications.statusDriverAssigned.tr,
      'ready_for_pickup' => AppStrings.Notifications.statusReadyForPickup.tr,
      'on_the_way' => AppStrings.Notifications.statusOnTheWay.tr,
      'picked_up' => AppStrings.Notifications.statusPickedUp.tr,
      'delivered' => AppStrings.Notifications.statusDelivered.tr,
      'cancelled' => AppStrings.Notifications.statusCancelled.tr,
      _ => ToukhNotificationStyleResolver.statusChipFallback(chipKey),
    };
  }

  static String? categoryLabel(ToukhNotification notification) {
    return switch (notification.category.trim().toLowerCase()) {
      ToukhNotificationCategory.message =>
        AppStrings.Notifications.categoryMessage.tr,
      ToukhNotificationCategory.system =>
        AppStrings.Notifications.categorySystem.tr,
      ToukhNotificationCategory.support =>
        AppStrings.Notifications.categorySupport.tr,
      ToukhNotificationCategory.order =>
        AppStrings.Notifications.categoryOrder.tr,
      _ => null,
    };
  }
}
