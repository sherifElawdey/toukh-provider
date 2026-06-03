import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/core/updates/app_version_gate_service.dart';
import 'package:toukh_provider/core/storage/backblaze_b2_client.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/core/config/twilio_environment.dart';
import 'package:toukh_provider/data/repositories/firebase_auth_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_home_service_categories_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_dashboard_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_orders_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_notification_inbox_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_profile_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_gallery_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_menu_repository.dart';
import 'package:toukh_provider/data/services/otp_service_stub.dart';
import 'package:toukh_provider/data/services/release_misconfigured_otp_repository.dart';
import 'package:toukh_provider/data/services/twilio_verify_otp_repository.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/domain/repositories/home_service_categories_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_menu_repository.dart';
import 'package:toukh_provider/domain/services/driver_matching_service.dart';
import 'package:toukh_provider/domain/services/order_qr_service.dart';
import 'package:toukh_provider/domain/repositories/notification_inbox_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_profile_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/registration_otp_args_holder.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/features/notifications/cubit/notifications_cubit.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';

import 'package:toukh_ui/toukh_ui.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseMessaging>(
    () => FirebaseMessaging.instance,
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(getIt<FirebaseAuth>()),
  );
  getIt.registerLazySingleton<ProviderProfileRepository>(
    () => FirestoreProviderProfileRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<NotificationInboxRepository>(
    () => FirestoreNotificationInboxRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<HomeServiceCategoriesRepository>(
    () => FirestoreHomeServiceCategoriesRepository(
      getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<ProviderGalleryRepository>(
    () => FirestoreProviderGalleryRepository(
      getIt<FirebaseFirestore>(),
      getIt<MediaUploadService>(),
    ),
  );
  getIt.registerLazySingleton<ProviderMenuRepository>(
    () => FirestoreProviderMenuRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<FirestoreProviderDashboardRepository>(
    () => FirestoreProviderDashboardRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<ProviderDashboardRepository>(
    () => getIt<FirestoreProviderDashboardRepository>(),
  );
  getIt.registerLazySingleton<FirestoreProviderOrdersRepository>(
    () => FirestoreProviderOrdersRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<ProviderOrdersRepository>(
    () => getIt<FirestoreProviderOrdersRepository>(),
  );
  getIt.registerLazySingleton<OtpRepository>(() {
    final twilioConfig = twilioVerifyConfigFromEnvironment();
    if (twilioConfig.isComplete) {
      return TwilioVerifyOtpRepository(
        TwilioVerifyClient(config: twilioConfig),
      );
    }
    if (kReleaseMode) {
      debugPrint(
        '[toukh_provider] Twilio Verify dart-defines missing in release build. '
        'OTP will fail until TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and '
        'TWILIO_VERIFY_SERVICE_SID are set at build time.',
      );
      return ReleaseMisconfiguredOtpRepository();
    }
    debugPrint(
      '[toukh_provider] Twilio not configured — using OtpServiceStub (code 123456).',
    );
    return OtpServiceStub();
  });

  getIt.registerLazySingleton<RegistrationOtpArgsHolder>(
    RegistrationOtpArgsHolder.new,
  );

  getIt.registerLazySingleton<BackblazeB2Client>(() => BackblazeB2Client());
  getIt.registerLazySingleton<MediaUploadService>(
    () => MediaUploadService(getIt<BackblazeB2Client>()),
  );

  getIt.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      authRepository: getIt<AuthRepository>(),
      profileRepository: getIt<ProviderProfileRepository>(),
      mediaUploadService: getIt<MediaUploadService>(),
      galleryRepository: getIt<ProviderGalleryRepository>(),
    ),
  );

  getIt.registerLazySingleton<OnboardingCubit>(
    () => OnboardingCubit(getIt<AuthCubit>()),
  );

  getIt.registerLazySingleton<SettingsCubit>(SettingsCubit.new);

  getIt.registerLazySingleton<AppVersionGateService>(
    AppVersionGateService.new,
  );

  getIt.registerLazySingleton<ProviderOrdersCubit>(
    () => ProviderOrdersCubit(
      authCubit: getIt<AuthCubit>(),
      ordersRepository: getIt<ProviderOrdersRepository>(),
    )..start(),
  );

  getIt.registerLazySingleton<NotificationsCubit>(
    () => NotificationsCubit(getIt<NotificationInboxRepository>()),
  );
}
