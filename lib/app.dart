import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/notifications/push_bootstrap.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/core/notifications/notification_router_holder.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/notifications/cubit/notifications_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_provider/l10n/app_translations.dart';
import 'package:toukh_provider/router/app_router.dart';

class ToukhProviderApp extends StatefulWidget {
  const ToukhProviderApp({super.key});

  @override
  State<ToukhProviderApp> createState() => _ToukhProviderAppState();
}

class _ToukhProviderAppState extends State<ToukhProviderApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final authCubit = getIt<AuthCubit>();
    final onboardingCubit = getIt<OnboardingCubit>();
    final settingsCubit = getIt<SettingsCubit>();
    unawaited(authCubit.subscribe());
    _router = createAppRouter(
      authCubit: authCubit,
      onboardingCubit: onboardingCubit,
      settingsCubit: settingsCubit,
    );
    NotificationRouterHolder.router = _router;

    final notificationsCubit = getIt<NotificationsCubit>();
    void onAuth(AuthState state) {
      if (state is Authenticated &&
          state.profile.status == ProviderAccountStatus.active) {
        notificationsCubit.bindUser(state.user.uid);
        unawaited(_syncFcmForActiveProvider(state.user.uid));
      } else {
        notificationsCubit.bindUser(null);
      }
    }

    onAuth(authCubit.state);
    _authSub = authCubit.stream.listen(onAuth);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(configureProviderPush());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  Future<void> _onAppResumed() async {
    final auth = getIt<AuthCubit>().state;
    if (auth is! Authenticated ||
        auth.profile.status != ProviderAccountStatus.active) {
      return;
    }
    await ToukhPushMessaging.instance.requestPermission();
    await _syncFcmForActiveProvider(auth.user.uid);
  }

  Future<void> _syncFcmForActiveProvider(String uid) async {
    await ToukhFcmTokenSync.syncOnAppOpen(
      uid: uid,
      firestore: FirebaseFirestore.instance,
      recipient: ToukhNotificationRecipient.provider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
        BlocProvider<OnboardingCubit>.value(value: getIt<OnboardingCubit>()),
        BlocProvider<SettingsCubit>.value(value: getIt<SettingsCubit>()),
        BlocProvider<NotificationsCubit>.value(
          value: getIt<NotificationsCubit>(),
        ),
      ],
      child: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, settings) {
          Get.updateLocale(settings.locale);
          Get.changeThemeMode(settings.themeMode);
        },
        builder: (context, settings) {
          return GetMaterialApp.router(
            title: AppStrings.App.title.tr,
            debugShowCheckedModeBanner: false,
            translations: AppTranslations(),
            fallbackLocale: const Locale('en'),
            theme: ToukhTheme.light(),
            darkTheme: ToukhTheme.dark(),
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            routeInformationProvider: _router.routeInformationProvider,
            routeInformationParser: _router.routeInformationParser,
            routerDelegate: _router.routerDelegate,
          );
        },
      ),
    );
  }
}
