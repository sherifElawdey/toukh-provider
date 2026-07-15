import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/app.dart';
import 'package:toukh_provider/core/media/safe_image_pick.dart';
import 'package:toukh_provider/core/notifications/background_message_handler.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/firebase_options.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/core/updates/app_version_gate_service.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installImagePickErrorLogging();
  await initToukhMapsPlatform();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, st) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('$st');
    rethrow;
  }

  FirebaseMessaging.onBackgroundMessage(providerBackgroundMessageHandler);

  try {
    await configureDependencies();
  } catch (e, st) {
    debugPrint('configureDependencies failed: $e');
    debugPrint('$st');
    rethrow;
  }

  final settingsCubit = getIt<SettingsCubit>();
  await settingsCubit.hydrate();
  final hydrated = settingsCubit.state;
  Get.updateLocale(hydrated.locale);
  Get.changeThemeMode(hydrated.themeMode);

  unawaited(getIt<AppVersionGateService>().ensureChecked());

  // Push init runs after first frame in [ToukhProviderApp] so iOS never blocks on FCM/APNS.
  runApp(const ToukhProviderApp());
}
