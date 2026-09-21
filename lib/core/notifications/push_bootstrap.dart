import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/notifications/notification_navigation.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_controller.dart';
import 'package:toukh_provider/shared/shared.dart';

Future configureProviderPush() async {
  await ToukhPushBootstrap.configure(
    // Simple ecommerce: do not prompt for notification permission on launch.
    requestPermission: false,
    initialize: () => ToukhPushMessaging.instance.initialize(
      recipient: ToukhNotificationRecipient.provider,
      firestore: FirebaseFirestore.instance,
      onTap: handleProviderNotificationTap,
      onForegroundNotification: (notification) {
        if (notification.type == ToukhOrderNotificationTypes.orderPlaced ||
            notification.type ==
                ToukhHomeServiceNotificationTypes.homeServiceRequestPlaced) {
          ProviderOrderAlertController.instance.show(notification);
          return true;
        }
        return false;
      },
    ),
  );
}
