import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/router/provider_redirect.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/core/updates/app_version_gate_service.dart';
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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _breathing;
  late final Animation<double> _fade;
  late final Animation<double> _scaleUp;
  late final Animation<double> _breathe;

  /// Prevents welcome / auth redirects until Remote Config version check finishes.
  bool _versionGateCompleted = false;

  void _logSplash(String message) {
    debugPrint('[AuthFlow][Splash] $message');
  }

  void _leaveSplashIfNeeded(BuildContext context) {
    if (!_versionGateCompleted) return;
    final routerState = GoRouterState.of(context);
    if (routerState.matchedLocation != AppRoutes.splash) return;

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
        if (GoRouterState.of(context).matchedLocation != AppRoutes.splash) {
          return;
        }
        context.go(AppRoutes.welcome);
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
        if (GoRouterState.of(context).matchedLocation != AppRoutes.splash) {
          return;
        }
        context.go(next);
        _logSplash('navigate -> $next');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _breathing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );

    _scaleUp = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

    _breathe = Tween<double>(
      begin: 1.0,
      end: 1.045,
    ).animate(CurvedAnimation(parent: _breathing, curve: Curves.easeInOut));

    _entrance.forward().then((_) {
      if (mounted) _breathing.repeat(reverse: true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapAfterFirstFrame());
    });
  }

  Future<void> _bootstrapAfterFirstFrame() async {
    if (!mounted) return;
    final router = GoRouter.of(context);
    try {
      final gate = getIt<AppVersionGateService>();
      final result = await gate.ensureChecked();
      if (!mounted) return;
      if (result.needsUpdate && gate.storeUri != null) {
        router.go(AppRoutes.appUpdate, extra: gate.storeUri);
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
  void dispose() {
    _entrance.dispose();
    _breathing.dispose();
    super.dispose();
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
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.thirdColor.withValues(alpha: 0.65),
                AppColors.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  return BlocBuilder<OnboardingCubit, OnboardingState>(
                    builder: (context, onboardingState) {
                      final statusKey = _splashStatusLine(
                        authState,
                        onboardingState.gate,
                      );
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation:
                                Listenable.merge([_entrance, _breathing]),
                            builder: (context, child) {
                              final breatheFactor =
                                  _entrance.isCompleted ? _breathe.value : 1.0;
                              final scale = _scaleUp.value * breatheFactor;
                              return FadeTransition(
                                opacity: _fade,
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: ToukhServiceLogo(
                              size: 140,
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _fade,
                            child: CustomText(
                              AppStrings.App.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    fontSize: 32,
                                    color: AppColors.splashTitle,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          FadeTransition(
                            opacity: _fade,
                            child: Padding(
                              padding: AppSizes.screenHorizontal,
                              child: CustomText(
                                statusKey,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.62),
                                      height: 1.35,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
