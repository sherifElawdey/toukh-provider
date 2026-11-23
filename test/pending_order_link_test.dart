import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/router/pending_order_link.dart';
import 'package:toukh_provider/core/router/provider_redirect.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/auth/cubit/auth_state.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';

class _User implements User {
  @override
  String get uid => 'p1';
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
    getIt.registerSingleton<AppVersionGateService>(_VersionGate());
  });
  setUp(PendingOrderLink.take);

  const settings = SettingsState(
    themeMode: ThemeMode.system,
    locale: Locale('en'),
    firstLaunchCompleted: true,
  );
  final store = Authenticated(
    user: _User(),
    profile: ProviderProfile.fromFirestore('p1', {
      'name': 'Store',
      'status': 'active',
      'phoneVerified': true,
      'registrationExtrasComplete': true,
    }),
  );

  String? go(String loc, AuthState auth, [OnboardingGate gate = OnboardingGate.ready]) =>
      resolveProviderRedirect(
        matchedLocation: loc,
        auth: auth,
        onboardingGate: gate,
        settings: settings,
      );

  test('an order link opened signed out comes back after login', () {
    expect(go('/orders/abc123', const Unauthenticated()), AppRoutes.login);
    expect(go(AppRoutes.login, const Unauthenticated()), isNull);
    expect(go(AppRoutes.login, store), '/orders/abc123');
    expect(go('/orders/abc123', store), isNull);
    // Used once: the next sign-in lands on home as usual.
    expect(go(AppRoutes.splash, store), AppRoutes.home);
  });

  test('an order link survives the splash on a cold start', () {
    expect(go('/orders/abc123', store, OnboardingGate.checking), AppRoutes.splash);
    expect(go(AppRoutes.splash, store), '/orders/abc123');
  });

  test('other links are not kept', () {
    expect(go('/menu', const Unauthenticated()), AppRoutes.login);
    expect(go(AppRoutes.login, store), AppRoutes.home);
  });
}
