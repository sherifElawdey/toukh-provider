import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:toukh_provider/app.dart';
import 'package:toukh_provider/core/notifications/push_bootstrap.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/firebase_options.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/core/updates/app_version_gate_service.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Improves GoogleMap rendering on many Android devices (TextureView vs hybrid).
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final mapsImpl = GoogleMapsFlutterPlatform.instance;
    if (mapsImpl is GoogleMapsFlutterAndroid) {
      mapsImpl.useAndroidViewSurface = true;
    }
  }

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

  FirebaseMessaging.onBackgroundMessage(
    ToukhPushMessaging.firebaseMessagingBackgroundHandler,
  );

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

  await configureProviderPush();

  unawaited(getIt<AppVersionGateService>().ensureChecked());

  runApp(const ToukhProviderApp());
}
