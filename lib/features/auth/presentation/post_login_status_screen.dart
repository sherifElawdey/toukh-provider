import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/widgets/post_login_sheet_body.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown once after a successful login when the provider account is not [active].
/// Presents status details, then navigates to the usual destination route.
class PostLoginStatusScreen extends StatefulWidget {
  const PostLoginStatusScreen({super.key});

  @override
  State<PostLoginStatusScreen> createState() => _PostLoginStatusScreenState();
}

class _PostLoginStatusScreenState extends State<PostLoginStatusScreen> {
  void _logStatus(String message) {
    debugPrint('[AuthFlow][PostLoginStatus] $message');
  }

  Future<void> _openSupportEmail() async {
    final uri = Uri.parse(
      'mailto:${AppConstants.supportServicesEmail}?subject=${Uri.encodeComponent('Toukh Service — Support')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current is Unauthenticated ||
          current is AuthFailure ||
          (current is Authenticated &&
              current.profile.status == ProviderAccountStatus.active),
      listener: (context, state) {
        if (state is Unauthenticated || state is AuthFailure) {
          _logStatus('auth became ${state.runtimeType} -> navigate login');
          context.go(AppRoutes.login);
          return;
        }
        if (state is Authenticated &&
            state.profile.status == ProviderAccountStatus.active) {
          _logStatus('auth became active -> navigate splash');
          context.go(AppRoutes.splash);
        }
      },
      builder: (context, authState) {
        if (authState is Authenticated) {
          final auth = authState;
          _logStatus(
            'render status page: status=${auth.profile.status.name}, '
            'phoneVerified=${auth.profile.phoneVerified}, '
            'extrasComplete=${auth.profile.registrationExtrasComplete}',
          );
          return Scaffold(
            body: PostLoginSheetBody(
              auth: auth,
              onContinue: () {
                GoRouter.of(context).go(postLoginContinueRoute(auth));
              },
              onSignOut: () {
                final router = GoRouter.of(context);
                context.read<AuthCubit>().signOut().then((_) {
                  if (!mounted) return;
                  router.go(AppRoutes.login);
                });
              },
              onContactSupport: _openSupportEmail,
            ),
          );
        }

        // Never show a blank screen while auth is rehydrating after app restart.
        _logStatus('render rehydrate loader: state=${authState.runtimeType}');
        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.thirdColor.withValues(alpha: 0.55),
                  AppColors.surface,
                ],
              ),
            ),
            child: const SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ToukhServiceLogo(size: 72),
                    SizedBox(height: 20),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Destination after the post-login sheet (resolver continues from [AppRoutes.splash]).
String postLoginContinueRoute(Authenticated auth) {
  final p = auth.profile;
  switch (p.status) {
    case ProviderAccountStatus.blocked:
      return AppRoutes.accountBlocked;
    case ProviderAccountStatus.pending:
    case ProviderAccountStatus.unverified:
      if (!p.phoneVerified) return AppRoutes.accountVerifyPhone;
      return AppRoutes.splash;
    case ProviderAccountStatus.active:
      return AppRoutes.splash;
    case ProviderAccountStatus.deleted:
      return AppRoutes.login;
  }
}
