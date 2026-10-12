import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/core/notifications/notification_navigation.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_controller.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future configureProviderPush() async {
  await ToukhPushBootstrap.configure(
    initialize: () => ToukhPushMessaging.instance.initialize(
      recipient: ToukhNotificationRecipient.provider,
      firestore: FirebaseFirestore.instance,
      onTap: handleProviderNotificationTap,
      onForegroundNotification: (notification) {
        final orderAlert = notification.type ==
                ToukhOrderNotificationTypes.orderPlaced ||
            notification.type ==
                ToukhHomeServiceNotificationTypes.homeServiceRequestPlaced;
        if (kIsWeb) {
          if (orderAlert) {
            ProviderOrderAlertController.instance.show(
              notification,
              playSound: false,
            );
          }
          ToukhWebAlert.present(notification);
          return true;
        }
        if (orderAlert) {
          ProviderOrderAlertController.instance.show(notification);
          return true;
        }
        return false;
      },
    ),
  );
}
