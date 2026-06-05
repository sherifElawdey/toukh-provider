import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/notifications/notification_navigation.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_controller.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future<void> configureProviderPush() async {
  await ToukhPushBootstrap.configure(
    initialize: () => ToukhPushMessaging.instance.initialize(
      recipient: ToukhNotificationRecipient.provider,
      firestore: FirebaseFirestore.instance,
      onTap: handleProviderNotificationTap,
      onForegroundNotification: (notification) {
        if (notification.type == ToukhOrderNotificationTypes.orderPlaced) {
          ProviderOrderAlertController.instance.show(notification);
        }
      },
    ),
  );
}
