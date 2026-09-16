import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/router/provider_redirect.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

String _splashStatusLine(AuthState auth, OnboardingGate gate) {
  switch (auth) {
    case AuthInitial():
    case AuthLoading():
      return AppStrings.Splash.checkingAccount;
    case AuthenticatedNoProfile():
      return AppStrings.Auth.profilePendingSubtitle;
    case Authenticated():
      final status = auth.profile.status;
      if (status == ProviderAccountStatus.active &&
          gate == OnboardingGate.checking) {
        return AppStrings.Splash.preparingApp;
      }
      return AppStrings.Common.loading;
    case AuthFailure():
    case Unauthenticated():
      return AppStrings.Common.loading;
  }
}

class _SplashScreenState extends State<SplashScreen> {
  /// Prevents welcome / auth redirects until Remote Config version check finishes.
  bool _versionGateCompleted = false;

  void _logSplash(String message) {
    debugPrint('[AuthFlow][Splash] $message');
  }

  void _leaveSplashIfNeeded(BuildContext context) {
    if (!_versionGateCompleted ||
        !HavitSplashHold.instance.elapsed ||
        !context.mounted) {
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router == null) return;

    final matchedLocation = router.state.matchedLocation;
    if (matchedLocation != AppRoutes.splash) return;

    final auth = context.read<AuthCubit>().state;
    final gate = context.read<OnboardingCubit>().state.gate;
    final settings = context.read<SettingsCubit>().state;
    _logSplash(
      'evaluate: auth=${auth.runtimeType}, gate=${gate.name}, '
      'firstLaunchCompleted=${settings.firstLaunchCompleted}',
    );

    if (!settings.firstLaunchCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final r = GoRouter.maybeOf(context);
        if (r == null || r.state.matchedLocation != AppRoutes.splash) {
          return;
        }
        r.go(AppRoutes.welcome);
        _logSplash('navigate -> ${AppRoutes.welcome}');
      });
      return;
    }

    final next = resolveProviderRedirect(
      matchedLocation: AppRoutes.splash,
      auth: auth,
      onboardingGate: gate,
      settings: settings,
    );
    if (next != null && next != AppRoutes.splash) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final r = GoRouter.maybeOf(context);
        if (r == null || r.state.matchedLocation != AppRoutes.splash) {
          return;
        }
        r.go(next);
        _logSplash('navigate -> $next');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    HavitSplashHold.instance.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAfterFirstFrame());
    });
  }

  Future<void> _bootstrapAfterFirstFrame() async {
    if (!mounted) return;
    final router = GoRouter.of(context);
    try {
      final gate = getIt<AppVersionGateService>();
      final results = await Future.wait<Object?>([
        gate.ensureChecked(),
        HavitSplashHold.instance.waitUntilElapsed(),
      ]);
      if (!mounted) return;
      final result = results[0] as AppUpdateGateResult;
      if (result.needsUpdate) {
        if (router.state.matchedLocation == AppRoutes.splash) {
          router.go(AppRoutes.appUpdate, extra: gate.storeUri);
        }
        return;
      }
    } finally {
      _versionGateCompleted = true;
      if (mounted) {
        _leaveSplashIfNeeded(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, _) => _leaveSplashIfNeeded(context),
        ),
        BlocListener<OnboardingCubit, OnboardingState>(
          listener: (context, _) => _leaveSplashIfNeeded(context),
        ),
        BlocListener<SettingsCubit, SettingsState>(
          listener: (context, _) => _leaveSplashIfNeeded(context),
        ),
      ],
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const HavitSplashView(),
            Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  return BlocBuilder<OnboardingCubit, OnboardingState>(
                    builder: (context, onboardingState) {
                      final statusKey = _splashStatusLine(
                        authState,
                        onboardingState.gate,
                      );
                      return CustomText(
                        statusKey,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
