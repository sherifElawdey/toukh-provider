import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:toukh_provider/firebase_options.dart';
import 'package:toukh_ui/toukh_ui.dart';

@pragma('vm:entry-point')
Future<void> providerBackgroundMessageHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await ToukhPushMessaging.showBackgroundNotification(message);
}
