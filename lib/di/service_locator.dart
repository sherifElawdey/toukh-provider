import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/core/storage/backblaze_b2_client.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/data/repositories/firebase_auth_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_home_service_categories_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_dashboard_repository.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_profile_repository.dart';
import 'package:toukh_provider/data/repositories/hybrid_provider_dashboard_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';
import 'package:toukh_provider/data/services/otp_service_stub.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/domain/repositories/home_service_categories_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_profile_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/registration_otp_args_holder.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';

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
  getIt.registerLazySingleton<HomeServiceCategoriesRepository>(
    () => FirestoreHomeServiceCategoriesRepository(
      getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<FirestoreProviderDashboardRepository>(
    () => FirestoreProviderDashboardRepository(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<ProviderDashboardRepository>(
    () => HybridProviderDashboardRepository(
      getIt<FirestoreProviderDashboardRepository>(),
    ),
  );
  getIt.registerLazySingleton<OtpRepository>(() => OtpServiceStub());

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
    ),
  );

  getIt.registerLazySingleton<OnboardingCubit>(
    () => OnboardingCubit(getIt<AuthCubit>()),
  );

  getIt.registerLazySingleton<SettingsCubit>(SettingsCubit.new);
}
