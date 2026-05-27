import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/core/updates/app_version_gate_service.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_state.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';

/// Maps auth + onboarding + first-launch settings to the next route.
String? resolveProviderRedirect({
  required String matchedLocation,
  required AuthState auth,
  required OnboardingGate onboardingGate,
  required SettingsState settings,
}) {
  String authLabel() {
    if (auth is AuthInitial) return 'AuthInitial';
    if (auth is AuthLoading) return 'AuthLoading';
    if (auth is Unauthenticated) return 'Unauthenticated';
    if (auth is AuthFailure) return 'AuthFailure';
    if (auth is AuthenticatedNoProfile) return 'AuthenticatedNoProfile';
    if (auth is Authenticated) {
      final p = auth.profile;
      return 'Authenticated(status=${p.status.name}, '
          'phoneVerified=${p.phoneVerified}, '
          'extrasComplete=${p.registrationExtrasComplete})';
    }
    return auth.runtimeType.toString();
  }

  void logRedirect(String? to, String reason) {
    final dest = to ?? 'stay';
    // Verbose trace to understand navigation decisions during restarts.
    // ignore: avoid_print
    print(
      '[AuthFlow][Redirect] at=$matchedLocation -> $dest | reason=$reason | '
      'auth=${authLabel()} | gate=${onboardingGate.name} | '
      'firstLaunchCompleted=${settings.firstLaunchCompleted}',
    );
  }

  final loc = matchedLocation;

  final versionGate = getIt<AppVersionGateService>();
  if (versionGate.checked && versionGate.needsUpdate) {
    if (loc != AppRoutes.appUpdate) {
      logRedirect(AppRoutes.appUpdate, 'installed app below minimum version');
      return AppRoutes.appUpdate;
    }
    logRedirect(null, 'mandatory app update screen');
    return null;
  }

  if (!settings.firstLaunchCompleted &&
      loc != AppRoutes.welcome &&
      loc != AppRoutes.appUpdate &&
      loc != AppRoutes.splash) {
    logRedirect(AppRoutes.welcome, 'first launch not completed');
    return AppRoutes.welcome;
  }

  final inAuthFlow = AppRoutes.authFlowPaths.contains(loc);
  final inRegisterWizard = AppRoutes.registerWizardPaths.contains(loc);

  if (auth is AuthInitial || auth is AuthLoading) {
    if (inRegisterWizard ||
        inAuthFlow ||
        loc == AppRoutes.welcome ||
        loc == AppRoutes.appUpdate) {
      logRedirect(null, 'auth initializing/loading in allowed flow');
      return null;
    }
    final next = loc == AppRoutes.splash ? null : AppRoutes.splash;
    logRedirect(next, 'auth initializing/loading');
    return next;
  }

  if (auth is AuthFailure || auth is Unauthenticated) {
    if (loc == AppRoutes.requestSubmitted) return null;
    if (loc == AppRoutes.postLoginStatus) {
      logRedirect(AppRoutes.login, 'not authenticated while in post-login status');
      return AppRoutes.login;
    }
    if (inRegisterWizard ||
        inAuthFlow ||
        loc == AppRoutes.welcome ||
        loc == AppRoutes.appUpdate) {
      logRedirect(null, 'unauthenticated in allowed flow');
      return null;
    }
    logRedirect(AppRoutes.login, 'unauthenticated fallback');
    return AppRoutes.login;
  }

  if (auth is AuthenticatedNoProfile) {
    final next = loc == AppRoutes.profilePending ? null : AppRoutes.profilePending;
    logRedirect(next, 'authenticated without provider profile');
    return next;
  }

  if (auth is Authenticated) {
    final profile = auth.profile;
    final status = profile.status;

    if (status == ProviderAccountStatus.deleted) {
      final next = loc == AppRoutes.login ? null : AppRoutes.login;
      logRedirect(next, 'deleted account');
      return next;
    }

    if (loc == AppRoutes.postLoginStatus) {
      if (status == ProviderAccountStatus.active) {
        switch (onboardingGate) {
          case OnboardingGate.checking:
            return AppRoutes.splash;
          case OnboardingGate.needsPermissions:
            return AppRoutes.permissions;
          case OnboardingGate.ready:
            return AppRoutes.home;
        }
      }
      logRedirect(null, 'on postLoginStatus route');
      return null;
    }

    switch (status) {
      case ProviderAccountStatus.deleted:
        final next = loc == AppRoutes.login ? null : AppRoutes.login;
        logRedirect(next, 'deleted account in status switch');
        return next;

      case ProviderAccountStatus.blocked:
        final next = loc == AppRoutes.accountBlocked ? null : AppRoutes.accountBlocked;
        logRedirect(next, 'blocked account');
        return next;

      case ProviderAccountStatus.unverified:
      case ProviderAccountStatus.pending:
        if (!profile.phoneVerified) {
          const allowed = <String>{
            AppRoutes.accountVerifyPhone,
            AppRoutes.verifyOtp,
            AppRoutes.postLoginStatus,
            AppRoutes.registerReview,
          };
          if (allowed.contains(loc)) {
            logRedirect(null, 'pending/unverified phone not verified on allowed route');
            return null;
          }
          logRedirect(
            AppRoutes.accountVerifyPhone,
            'pending/unverified and phone not verified',
          );
          return AppRoutes.accountVerifyPhone;
        }

        if (!profile.registrationExtrasComplete) {
          final needsMenu = profile.isRestaurantShop;
          final target = needsMenu
              ? AppRoutes.registrationMenu
              : AppRoutes.registrationPortfolio;
          final allowed = <String>{
            AppRoutes.registrationMenu,
            AppRoutes.registrationPortfolio,
          };
          if (allowed.contains(loc)) return null;
          logRedirect(target, 'pending/unverified needs registration extras');
          return target;
        }

        if (profile.registrationExtrasComplete) {
          final next = loc == AppRoutes.pendingApproval
              ? null
              : AppRoutes.pendingApproval;
          logRedirect(next, 'pending/unverified after extras complete');
          return next;
        }

      case ProviderAccountStatus.active:
        switch (onboardingGate) {
          case OnboardingGate.checking:
            if (loc == AppRoutes.splash ||
                loc == AppRoutes.permissions ||
                loc == AppRoutes.appUpdate) {
              logRedirect(null, 'active + onboarding checking in allowed route');
              return null;
            }
            logRedirect(AppRoutes.splash, 'active + onboarding checking');
            return AppRoutes.splash;
          case OnboardingGate.needsPermissions:
            final next = loc == AppRoutes.permissions ? null : AppRoutes.permissions;
            logRedirect(next, 'active needs permissions');
            return next;
          case OnboardingGate.ready:
            if (AppRoutes.isShellPathOrSubroute(loc)) {
              logRedirect(null, 'active + ready on shell route');
              return null;
            }
            logRedirect(AppRoutes.home, 'active + ready');
            return AppRoutes.home;
        }
    }
  }

  logRedirect(null, 'no redirect rule matched');
  return null;
}
