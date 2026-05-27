import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/notifications/notification_navigation.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future<void> configureProviderPush() async {
  await ToukhPushMessaging.instance.initialize(
    recipient: ToukhNotificationRecipient.provider,
    firestore: FirebaseFirestore.instance,
    onTap: handleProviderNotificationTap,
  );
}
