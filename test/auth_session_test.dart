import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/router/provider_redirect.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/core/storage/media_upload_service.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';
import 'package:toukh_provider/domain/repositories/delivery_company_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_profile_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/delivery_company/registration/delivery_company_registration_cubit.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';

class _User implements User {
  @override
  String get uid => 'shared-login';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Credential implements UserCredential {
  @override
  User? get user => _User();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Auth implements AuthRepository {
  _Auth({required this.loginExists});
  final bool loginExists;
  int deletes = 0;
  int signOuts = 0;

  @override
  User? get currentUser => null;
  @override
  Future<UserCredential> registerWithPhonePassword({
    required String phone,
    required String password,
  }) async {
    if (loginExists) throw FirebaseAuthException(code: 'email-already-in-use');
    return _Credential();
  }

  @override
  Future<UserCredential> signInWithPhonePassword({
    required String phone,
    required String password,
  }) async => _Credential();
  @override
  Future<void> deleteAccount() async => deletes++;
  @override
  Future<void> signOut() async => signOuts++;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Profiles implements ProviderProfileRepository {
  @override
  Future<ProviderProfile?> getProfile(String uid) async => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Companies implements DeliveryCompanyRepository {
  @override
  Future<DeliveryCompany?> getCompany(String uid) async => null;
  @override
  Future<void> createCompany(DeliveryCompany company) async =>
      throw StateError('write failed');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Media implements MediaUploadService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Gallery implements ProviderGalleryRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Geofence implements GeofenceService {
  @override
  Future<ServiceArea?> findContaining({
    required double lat,
    required double lng,
  }) async => _Area();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Area implements ServiceArea {
  @override
  String get id => 'area';
  @override
  String get name => 'Toukh';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _VersionGate implements AppVersionGateService {
  @override
  bool get checked => true;
  @override
  bool get needsUpdate => false;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUpAll(() {
    getIt.registerSingleton<GeofenceService>(_Geofence());
    getIt.registerSingleton<AppVersionGateService>(_VersionGate());
  });

  Future<_Auth> failSignUp({required bool loginExists}) async {
    final auth = _Auth(loginExists: loginExists);
    final cubit = AuthCubit(
      authRepository: auth,
      profileRepository: _Profiles(),
      mediaUploadService: _Media(),
      galleryRepository: _Gallery(),
      companyRepository: _Companies(),
    );
    await cubit.registerDeliveryCompany(
      const DeliveryCompanyRegistrationData(
        companyName: 'Co',
        managerName: 'Manager',
        phone: '+201000000000',
        password: 'secret1',
        lat: 30,
        lng: 31,
        formattedAddress: 'Toukh',
        city: 'toukh',
      ),
    );
    await cubit.close();
    return auth;
  }

  test('failed sign-up keeps a login the other apps may share', () async {
    final auth = await failSignUp(loginExists: true);
    expect(auth.deletes, 0);
    expect(auth.signOuts, 1);
  });

  test('failed sign-up still removes the login it created', () async {
    final auth = await failSignUp(loginExists: false);
    expect(auth.deletes, 1);
  });

  String? redirect({required bool hasFirebaseUser, String loc = AppRoutes.orders}) =>
      resolveProviderRedirect(
        matchedLocation: loc,
        auth: const AuthFailure(message: 'Could not save'),
        onboardingGate: OnboardingGate.ready,
        settings: const SettingsState(
          themeMode: ThemeMode.system,
          locale: Locale('en'),
          firstLaunchCompleted: true,
        ),
        hasFirebaseUser: hasFirebaseUser,
      );

  test('a failed action does not send a signed-in user to login', () {
    expect(redirect(hasFirebaseUser: true), isNull);
  });

  test('a failed action without a session still goes to login', () {
    expect(redirect(hasFirebaseUser: false), AppRoutes.login);
  });
}
