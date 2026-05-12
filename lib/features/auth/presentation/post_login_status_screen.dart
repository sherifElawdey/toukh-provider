import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
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
            body: _PostLoginSheetBody(
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

class _PostLoginSheetBody extends StatefulWidget {
  const _PostLoginSheetBody({
    required this.auth,
    required this.onContinue,
    required this.onSignOut,
    required this.onContactSupport,
  });

  final Authenticated auth;
  final VoidCallback onContinue;
  final VoidCallback onSignOut;
  final VoidCallback onContactSupport;

  @override
  State<_PostLoginSheetBody> createState() => _PostLoginSheetBodyState();
}

class _PostLoginSheetBodyState extends State<_PostLoginSheetBody> {
  Timer? _ticker;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    final info = widget.auth.profile.blockInfo;
    if (widget.auth.profile.status == ProviderAccountStatus.blocked &&
        info != null &&
        info.expiresAt != null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    if (d <= Duration.zero) return AppStrings.AccountStatus.blockedLifted.tr;
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) {
      return '${days}d ${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _title(ProviderProfile p) {
    switch (p.status) {
      case ProviderAccountStatus.blocked:
        return AppStrings.AccountStatus.blockedTitle.tr;
      case ProviderAccountStatus.pending:
        return AppStrings.AccountStatus.postLoginPendingTitle.tr;
      case ProviderAccountStatus.unverified:
        if (!p.phoneVerified) {
          return AppStrings.AccountStatus.verifyPhoneTitle.tr;
        }
        return AppStrings.AccountStatus.unverifiedTitle.tr;
      default:
        return AppStrings.AccountStatus.unverifiedTitle.tr;
    }
  }

  String? _body(ProviderProfile p) {
    switch (p.status) {
      case ProviderAccountStatus.blocked:
        return null;
      case ProviderAccountStatus.pending:
        return AppStrings.AccountStatus.postLoginPendingBody.tr;
      case ProviderAccountStatus.unverified:
        if (!p.phoneVerified) {
          return AppStrings.AccountStatus.postLoginVerifyPhonePrompt.tr;
        }
        return AppStrings.AccountStatus.unverifiedSubtitle.tr;
      default:
        return AppStrings.AccountStatus.unverifiedSubtitle.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = widget.auth.profile;
    final status = p.status;
    final dateFormat = DateFormat.yMMMMd().add_jm();
    final info = p.blockInfo;
    final remaining = info?.remaining(_now);

    return DecoratedBox(
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: AppSizes.screenPadding.copyWith(
            top: AppSizes.space2xl,
            bottom: AppSizes.space2xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                Center(
                  child: ToukhServiceLogo(
                    size: 56,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                Icon(
                  switch (status) {
                    ProviderAccountStatus.blocked => Icons.block_rounded,
                    ProviderAccountStatus.pending => Icons.hourglass_top_rounded,
                    ProviderAccountStatus.unverified => Icons.phone_android_rounded,
                    _ => Icons.info_outline_rounded,
                  },
                  size: 56,
                  color: status == ProviderAccountStatus.blocked
                      ? AppColors.error
                      : AppColors.secondColor,
                ),
                SizedBox(height: AppSizes.spaceMd),
                CustomText(
                  _title(p),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontHeadline,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondColor,
                    height: 1.2,
                  ),
                ),
                if (_body(p) != null) ...[
                  SizedBox(height: AppSizes.spaceMd),
                  Text(
                    _body(p)!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.family,
                      fontSize: AppSizes.fontBody,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.76),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (status == ProviderAccountStatus.blocked &&
                    info != null) ...[
                  SizedBox(height: AppSizes.spaceXl),
                  _detailTile(
                    scheme,
                    Icons.warning_amber_rounded,
                    AppStrings.AccountStatus.blockedReason.tr,
                    info.reason,
                  ),
                  SizedBox(height: AppSizes.spaceMd),
                  _detailTile(
                    scheme,
                    Icons.event_outlined,
                    AppStrings.AccountStatus.blockedSince.trParams({
                      'date': dateFormat.format(info.blockedAt),
                    }),
                    dateFormat.format(info.blockedAt),
                  ),
                  SizedBox(height: AppSizes.spaceMd),
                  _detailTile(
                    scheme,
                    Icons.timer_outlined,
                    info.isIndefinite
                        ? AppStrings.AccountStatus.blockedIndefinite.tr
                        : AppStrings.AccountStatus.blockedTimeRemaining.trParams({
                            'time': _formatRemaining(
                              remaining ?? Duration.zero,
                            ),
                          }),
                    '',
                    labelOnly: true,
                  ),
                ],
                if (status == ProviderAccountStatus.pending) ...[
                  SizedBox(height: AppSizes.spaceXl),
                  TextButton.icon(
                    onPressed: widget.onContactSupport,
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: CustomText(AppStrings.AccountStatus.postLoginContactUs),
                  ),
                ],
                SizedBox(height: AppSizes.space2xl),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: widget.onSignOut,
                        child: CustomText(AppStrings.AccountStatus.signOut),
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceMd),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: widget.onContinue,
                        child: CustomText(AppStrings.Common.continueLabel),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailTile(
    ColorScheme scheme,
    IconData icon,
    String label,
    String value, {
    bool labelOnly = false,
  }) {
    return Material(
      color: AppColors.thirdColor.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceBase,
          vertical: AppSizes.spaceMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSizes.iconLg, color: AppColors.secondColor),
            SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    label,
                    style: TextStyle(
                      fontSize: labelOnly
                          ? AppSizes.fontBody
                          : AppSizes.fontLabel,
                      fontWeight:
                          labelOnly ? FontWeight.w700 : FontWeight.w600,
                      color: labelOnly
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  if (!labelOnly && value.isNotEmpty) ...[
                    SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      value,
                      style: TextStyle(
                        fontSize: AppSizes.fontBody,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
