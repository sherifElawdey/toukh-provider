import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class PostLoginSheetBody extends StatefulWidget {
  const PostLoginSheetBody({
    super.key,
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
  State<PostLoginSheetBody> createState() => _PostLoginSheetBodyState();
}

class _PostLoginSheetBodyState extends State<PostLoginSheetBody> {
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
                  ProviderAccountStatus.unverified =>
                    Icons.phone_android_rounded,
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
              if (status == ProviderAccountStatus.blocked && info != null) ...[
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
                AppTextButton(
                  text: AppStrings.AccountStatus.postLoginContactUs,
                  icon: Icons.mail_outline_rounded,
                  onTap: widget.onContactSupport,
                ),
              ],
              SizedBox(height: AppSizes.space2xl),
              Row(
                children: [
                  Expanded(
                    child: AppTextButton(
                      text: AppStrings.AccountStatus.signOut,
                      onTap: widget.onSignOut,
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceMd),
                  Expanded(
                    flex: 2,
                    child: AppFilledButton(
                      text: AppStrings.Common.continueLabel,
                      onTap: widget.onContinue,
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
