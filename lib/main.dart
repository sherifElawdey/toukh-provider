import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toukh_provider/app.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/firebase_options.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const ToukhProviderApp());
}
