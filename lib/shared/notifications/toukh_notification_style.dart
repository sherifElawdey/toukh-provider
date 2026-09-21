import 'package:flutter/material.dart';

import '../icons/toukh_icons.dart';
import '../theme/app_colors.dart';
import 'toukh_notification.dart';
import 'toukh_notification_category.dart';
import 'toukh_order_notification_types.dart';

/// Visual styling for a notification list row.
class ToukhNotificationStyle {
  const ToukhNotificationStyle({
    required this.icon,
    required this.accentColor,
    this.statusChipKey,
  });

  final IconData icon;
  final Color accentColor;

  /// Normalized order status key for localized chip labels (e.g. `preparing`).
  final String? statusChipKey;
}

/// Maps [ToukhNotification] category/type/status to icons and colors.
abstract final class ToukhNotificationStyleResolver {
  ToukhNotificationStyleResolver._();

  static ToukhNotificationStyle resolve(ToukhNotification notification) {
    final category = notification.category.trim().toLowerCase();

    return switch (category) {
      ToukhNotificationCategory.message => ToukhNotificationStyle(
          icon: ToukhIcons.chat,
          accentColor: AppColors.secondColor,
        ),
      ToukhNotificationCategory.system => ToukhNotificationStyle(
          icon: ToukhIcons.info,
          accentColor: AppColors.appColor,
        ),
      ToukhNotificationCategory.support => ToukhNotificationStyle(
          icon: ToukhIcons.phone,
          accentColor: AppColors.warning,
        ),
      _ => _orderStyle(notification),
    };
  }

  static ToukhNotificationStyle _orderStyle(ToukhNotification notification) {
    final chipKey = _orderStatusChipKey(notification);
    return ToukhNotificationStyle(
      icon: _orderIcon(chipKey, notification.type),
      accentColor: _orderAccentColor(chipKey),
      statusChipKey: chipKey,
    );
  }

  static String? _orderStatusChipKey(ToukhNotification notification) {
    final fromPayload = notification.payload['orderStatus']?.toString();
    if (fromPayload != null && fromPayload.isNotEmpty) {
      return _normalizeOrderStatus(fromPayload);
    }
    return _statusKeyFromType(notification.type);
  }

  static String? _statusKeyFromType(String? type) {
    if (type == null || type.isEmpty) return null;
    return switch (type) {
      ToukhOrderNotificationTypes.orderPlaced => 'placed',
      ToukhOrderNotificationTypes.orderAccepted ||
      ToukhOrderNotificationTypes.preparing =>
        'preparing',
      ToukhOrderNotificationTypes.courierAssigned ||
      ToukhOrderNotificationTypes.driverAssigned =>
        'driver_assigned',
      ToukhOrderNotificationTypes.readyForPickup => 'ready_for_pickup',
      ToukhOrderNotificationTypes.outForDelivery => 'on_the_way',
      ToukhOrderNotificationTypes.partiallyPicked ||
      ToukhOrderNotificationTypes.pickupCompleted =>
        'picked_up',
      ToukhOrderNotificationTypes.delivered => 'delivered',
      ToukhOrderNotificationTypes.orderCancelled ||
      ToukhOrderNotificationTypes.orderRejected =>
        'cancelled',
      _ => null,
    };
  }

  static String? _normalizeOrderStatus(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'placed' || 'pending' => 'placed',
      'accepted' || 'preparing' => 'preparing',
      'courier_assigned' ||
      'driver_assigned' ||
      'courier_requested' =>
        'driver_assigned',
      'ready_for_pickup' => 'ready_for_pickup',
      'out_for_delivery' || 'on_the_way' => 'on_the_way',
      'picked_up' || 'partially_picked' => 'picked_up',
      'delivered' || 'completed' => 'delivered',
      'cancelled' || 'canceled' || 'rejected' => 'cancelled',
      _ => null,
    };
  }

  static IconData _orderIcon(String? chipKey, String? type) {
    return switch (chipKey) {
      'delivered' => ToukhIcons.success,
      'cancelled' => ToukhIcons.error,
      'on_the_way' || 'picked_up' => ToukhIcons.delivery,
      'driver_assigned' => ToukhIcons.vehicle,
      'ready_for_pickup' => ToukhIcons.store,
      'preparing' => ToukhIcons.restaurant,
      'placed' => ToukhIcons.orders,
      _ => switch (type) {
          ToukhOrderNotificationTypes.orderCancelled => ToukhIcons.error,
          ToukhOrderNotificationTypes.delivered => ToukhIcons.success,
          _ => ToukhIcons.orders,
        },
    };
  }

  static Color _orderAccentColor(String? chipKey) {
    return switch (chipKey) {
      'delivered' => AppColors.success,
      'cancelled' => AppColors.error,
      'on_the_way' || 'picked_up' => AppColors.appColor,
      'driver_assigned' => AppColors.secondColor,
      _ => AppColors.appColor,
    };
  }

  /// English fallback when no localized label is supplied.
  static String statusChipFallback(String? chipKey) {
    return switch (chipKey) {
      'placed' => 'Placed',
      'preparing' => 'Preparing',
      'driver_assigned' => 'Driver assigned',
      'ready_for_pickup' => 'Ready for pickup',
      'on_the_way' => 'On the way',
      'picked_up' => 'Picked up',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => '',
    };
  }

  /// English fallback for category badge (optional).
  static String categoryFallback(String category) {
    return switch (category.trim().toLowerCase()) {
      ToukhNotificationCategory.order => 'Order',
      ToukhNotificationCategory.message => 'Message',
      ToukhNotificationCategory.system => 'System',
      ToukhNotificationCategory.support => 'Support',
      _ => '',
    };
  }
}
