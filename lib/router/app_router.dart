import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/constants/legal_urls.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/router/go_router_auth_refresh.dart';
import 'package:toukh_provider/core/router/go_router_refresh.dart';
import 'package:toukh_provider/core/router/provider_redirect.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/core/updates/app_version_gate_service.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/account_status/presentation/account_phone_verification_screen.dart';
import 'package:toukh_provider/features/account_status/presentation/blocked_screen.dart';
import 'package:toukh_provider/features/account_status/presentation/unverified_screen.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/forgot_password_screen.dart';
import 'package:toukh_provider/features/auth/presentation/post_login_status_screen.dart';
import 'package:toukh_provider/features/auth/presentation/profile_pending_screen.dart';
import 'package:toukh_provider/features/auth/presentation/request_submitted_screen.dart';
import 'package:toukh_provider/features/auth/presentation/reset_password_screen.dart'
    show ResetPasswordRouteArgs, ResetPasswordScreen;
import 'package:toukh_provider/features/auth/presentation/splash_screen.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_screen.dart';
import 'package:toukh_provider/features/auth/registration_otp_args_holder.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_menu_repository.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_cubit.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/home_service_request_detail_screen.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_cubit.dart';
import 'package:toukh_provider/features/home/presentation/home_screen.dart';
import 'package:toukh_provider/features/menu/presentation/menu_builder_screen.dart';
import 'package:toukh_provider/features/notifications/presentation/notifications_screen.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/features/onboarding/presentation/permissions_screen.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/order_detail_screen.dart';
import 'package:toukh_provider/features/orders/presentation/orders_screen.dart';
import 'package:toukh_provider/features/pending/presentation/pending_approval_screen.dart';
import 'package:toukh_provider/features/portfolio/presentation/portfolio_screen.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/register_category_screen.dart';
import 'package:toukh_provider/features/registration/presentation/register_credentials_screen.dart';
import 'package:toukh_provider/features/registration/presentation/register_delivery_screen.dart';
import 'package:toukh_provider/features/registration/presentation/register_hours_screen.dart';
import 'package:toukh_provider/features/registration/presentation/register_kind_screen.dart';
import 'package:toukh_provider/features/registration/presentation/register_map_screen.dart';
import 'package:toukh_provider/features/registration/presentation/register_profile_screen.dart';
import 'package:toukh_provider/features/registration/presentation/register_review_screen.dart';
import 'package:toukh_provider/features/settings/presentation/about_app_screen.dart';
import 'package:toukh_provider/features/settings/presentation/account_details_screen.dart';
import 'package:toukh_provider/features/settings/presentation/legal_document_screen.dart';
import 'package:toukh_provider/features/settings/presentation/settings_screen.dart';
import 'package:toukh_provider/domain/repositories/provider_wallet_repository.dart';
import 'package:toukh_provider/features/wallet/cubit/wallet_cubit.dart';
import 'package:toukh_provider/features/wallet/presentation/wallet_screen.dart';
import 'package:toukh_provider/domain/repositories/provider_drivers_repository.dart';
import 'package:toukh_provider/features/drivers/cubit/manage_drivers_cubit.dart';
import 'package:toukh_provider/features/drivers/presentation/manage_drivers_screen.dart';
import 'package:toukh_provider/domain/repositories/provider_order_history_repository.dart';
import 'package:toukh_provider/features/order_history/cubit/order_history_cubit.dart';
import 'package:toukh_provider/features/order_history/presentation/order_history_screen.dart';
import 'package:toukh_provider/features/reviews/cubit/provider_reviews_cubit.dart';
import 'package:toukh_provider/features/reviews/presentation/provider_reviews_screen.dart';
import 'package:toukh_provider/domain/repositories/provider_reviews_repository.dart';
import 'package:toukh_provider/features/wallet/presentation/wallet_transactions_screen.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_overlay.dart';
import 'package:toukh_provider/features/shell/main_shell_scaffold.dart';
import 'package:toukh_provider/features/welcome/welcome_screen.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_provider/router/widgets/login_with_deleted_sheet.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/router/widgets/menu_or_gallery_tab_screen.dart';
import 'package:toukh_provider/router/widgets/verify_otp_missing_args_placeholder.dart';

final GlobalKey<NavigatorState> providerRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'providerRoot');

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required OnboardingCubit onboardingCubit,
  required SettingsCubit settingsCubit,
}) {
  return GoRouter(
    navigatorKey: providerRootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: Listenable.merge([
      GoRouterAuthRefresh(authCubit),
      GoRouterRefreshStream([
        onboardingCubit.stream,
        settingsCubit.stream,
      ]),
      getIt<AppVersionGateService>(),
    ]),
    redirect: (context, state) => resolveProviderRedirect(
          matchedLocation: state.matchedLocation,
          auth: authCubit.state,
          onboardingGate: onboardingCubit.state.gate,
          settings: settingsCubit.state,
        ),
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.appUpdate,
        builder: (context, state) {
          final extra = state.extra;
          final uri = extra is Uri
              ? extra
              : getIt<AppVersionGateService>().storeUri;
          if (uri == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) GoRouter.of(context).go(AppRoutes.splash);
            });
            return const Scaffold(body: SizedBox.shrink());
          }
          return AppMandatoryUpdateScreen(
            title: AppStrings.AppUpdate.title.tr,
            description: AppStrings.AppUpdate.description.tr,
            storeUri: uri,
            updateButtonLabel: AppStrings.AppUpdate.openStore.tr,
            imageAsset: 'assets/branding/app_icon_provider.png',
            imagePackage: null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginWithDeletedSheet(),
      ),
      GoRoute(
        path: AppRoutes.postLoginStatus,
        builder: (context, state) => const PostLoginStatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.requestSubmitted,
        builder: (context, state) => const RequestSubmittedScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (context, state) {
          final holder = getIt<RegistrationOtpArgsHolder>();
          final extra = state.extra;

          VerifyOtpRouteArgs? args;
          if (extra is VerifyOtpRouteArgs) {
            args = extra;
            if (extra.flow == VerifyOtpFlow.passwordReset) {
              holder.clear();
            }
          } else {
            args = holder.peek();
          }

          if (args == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              final authState = context.read<AuthCubit>().state;
              final router = GoRouter.of(context);
              if (authState is Authenticated && !authState.profile.phoneVerified) {
                router.go(AppRoutes.accountVerifyPhone);
              } else {
                router.go(AppRoutes.login);
              }
            });
            return const VerifyOtpMissingArgsPlaceholder();
          }

          return VerifyOtpScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! ResetPasswordRouteArgs) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                GoRouter.of(context).go(AppRoutes.forgotPassword);
              }
            });
            return const Scaffold(body: SizedBox.shrink());
          }
          return ResetPasswordScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.accountBlocked,
        builder: (context, state) => const BlockedScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountUnverified,
        builder: (context, state) => const UnverifiedScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountVerifyPhone,
        builder: (context, state) => const AccountPhoneVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profilePending,
        builder: (context, state) => const ProfilePendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.registrationMenu,
        builder: (context, state) => const MenuBuilderScreen(),
      ),
      GoRoute(
        path: AppRoutes.registrationPortfolio,
        builder: (context, state) => const PortfolioScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.legalTerms,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) => LegalDocumentScreen(
          titleKey: AppStrings.Settings.termsAndConditions,
          url: LegalUrls.terms,
        ),
      ),
      GoRoute(
        path: AppRoutes.legalPrivacy,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) => LegalDocumentScreen(
          titleKey: AppStrings.Settings.privacyPolicy,
          url: LegalUrls.privacy,
        ),
      ),
      GoRoute(
        path: AppRoutes.legalDeclaration,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) => LegalDocumentScreen(
          titleKey: AppStrings.Settings.declaration,
          url: LegalUrls.declaration,
        ),
      ),
      GoRoute(
        path: AppRoutes.accountDetails,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) {
          final auth = context.read<AuthCubit>().state;
          if (auth is! Authenticated) {
            return Scaffold(
              appBar: AppBar(title: CustomText(AppStrings.Settings.accountDetails)),
              body: const Center(child: CustomText('Sign in required')),
            );
          }
          return BlocProvider(
            create: (_) => RegistrationCubit()..seedFromProfile(auth.profile),
            child: const AccountDetailsScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.aboutApp,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) => const AboutAppScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/home-service-request/:requestId',
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) {
          final requestId = state.pathParameters['requestId']!;
          return BlocProvider.value(
            value: getIt<ProviderHomeServiceRequestsCubit>(),
            child: HomeServiceRequestDetailScreen(requestId: requestId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.wallet,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) {
          final auth = authCubit.state;
          if (auth is! Authenticated) {
            return Scaffold(
              body: Center(child: CustomText(AppStrings.Common.error.tr)),
            );
          }
          return BlocProvider(
            create: (_) => WalletCubit(
              getIt<ProviderWalletRepository>(),
              auth.user.uid,
            ),
            child: const WalletScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.walletTransactions,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) {
          final auth = authCubit.state;
          if (auth is! Authenticated) {
            return Scaffold(
              body: Center(child: CustomText(AppStrings.Common.error.tr)),
            );
          }
          return BlocProvider(
            create: (_) {
              final c = WalletHistoryCubit(
                getIt<ProviderWalletRepository>(),
                auth.user.uid,
              );
              c.loadInitial();
              return c;
            },
            child: const WalletTransactionsScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.reviews,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) {
          final auth = authCubit.state;
          if (auth is! Authenticated) {
            return Scaffold(
              body: Center(child: CustomText(AppStrings.Common.error.tr)),
            );
          }
          return BlocProvider(
            create: (_) => ProviderReviewsCubit(
              getIt<ProviderReviewsRepository>(),
              auth.user.uid,
            ),
            child: const ProviderReviewsScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.ordersHistory,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) {
          final auth = authCubit.state;
          if (auth is! Authenticated) {
            return Scaffold(
              body: Center(child: CustomText(AppStrings.Common.error.tr)),
            );
          }
          return BlocProvider(
            create: (_) {
              final c = OrderHistoryCubit(
                getIt<ProviderOrderHistoryRepository>(),
                auth.user.uid,
              );
              c.loadInitial();
              return c;
            },
            child: const OrderHistoryScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.manageDrivers,
        parentNavigatorKey: providerRootNavigatorKey,
        builder: (context, state) {
          final auth = authCubit.state;
          if (auth is! Authenticated) {
            return Scaffold(
              body: Center(child: CustomText(AppStrings.Common.error.tr)),
            );
          }
          return BlocProvider(
            create: (_) => ManageDriversCubit(
              getIt<ProviderDriversRepository>(),
              auth.user.uid,
            ),
            child: const ManageDriversScreen(),
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => RegistrationCubit(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.registerKind,
            builder: (context, state) => const RegisterKindScreen(),
          ),
          GoRoute(
            path: AppRoutes.registerCategory,
            builder: (context, state) => const RegisterCategoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.registerCredentials,
            builder: (context, state) => const RegisterCredentialsScreen(),
          ),
          GoRoute(
            path: AppRoutes.registerProfile,
            builder: (context, state) => const RegisterProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.registerMap,
            builder: (context, state) => const RegisterMapScreen(),
          ),
          GoRoute(
            path: AppRoutes.registerHours,
            builder: (context, state) => const RegisterHoursScreen(),
          ),
          GoRoute(
            path: AppRoutes.registerDelivery,
            builder: (context, state) => const RegisterDeliveryScreen(),
          ),
          GoRoute(
            path: AppRoutes.registerReview,
            builder: (context, state) => const RegisterReviewScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ProviderOrderAlertOverlay(
            child: MainShellScaffold(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) => HomeDashboardCubit(
                          authCubit: getIt<AuthCubit>(),
                          dashboardRepository: getIt<ProviderDashboardRepository>(),
                          menuRepository: getIt<ProviderMenuRepository>(),
                        )..start(),
                      ),
                      BlocProvider.value(value: getIt<ProviderOrdersCubit>()),
                      BlocProvider.value(
                        value: getIt<ProviderHomeServiceRequestsCubit>(),
                      ),
                    ],
                    child: const HomeScreen(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: MultiBlocProvider(
                    providers: [
                      BlocProvider.value(
                        value: getIt<ProviderOrdersCubit>(),
                      ),
                      BlocProvider.value(
                        value: getIt<ProviderHomeServiceRequestsCubit>(),
                      ),
                    ],
                    child: const OrdersScreen(),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    parentNavigatorKey: providerRootNavigatorKey,
                    builder: (context, state) {
                      final orderId = state.pathParameters['orderId']!;
                      return BlocProvider.value(
                        value: getIt<ProviderOrdersCubit>(),
                        child: OrderDetailScreen(orderId: orderId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.menu,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const MenuOrGalleryTabScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
