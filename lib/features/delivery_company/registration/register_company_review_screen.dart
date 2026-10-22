import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/twilio/twilio_otp_errors.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/otp_delivery_snack.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/features/delivery_company/registration/delivery_company_registration_cubit.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Last sign-up step: confirm details, create the account, send the OTP.
class RegisterCompanyReviewScreen extends StatefulWidget {
  const RegisterCompanyReviewScreen({super.key});

  @override
  State<RegisterCompanyReviewScreen> createState() =>
      _RegisterCompanyReviewScreenState();
}

class _RegisterCompanyReviewScreenState
    extends State<RegisterCompanyReviewScreen> {
  late final Future<ServiceArea?> _area;

  @override
  void initState() {
    super.initState();
    final loc = context.read<RegistrationCubit>().state;
    _area = loc.lat != null && loc.lng != null
        ? getIt<GeofenceService>().findContaining(lat: loc.lat!, lng: loc.lng!)
        : Future.value(null);
  }

  Future<void> _submit() async {
    final draft = context.read<DeliveryCompanyRegistrationCubit>().state;
    final loc = context.read<RegistrationCubit>().state;
    final phone = draft.phoneE164;
    if (!draft.isComplete || phone == null) {
      _snack(AppStrings.Auth.registrationDataMissing, AppSnackState.error);
      context.go(AppRoutes.registerCompany);
      return;
    }
    if (loc.lat == null || loc.lng == null) {
      _snack(AppStrings.Company.locationMissing, AppSnackState.warning);
      return;
    }

    final authCubit = context.read<AuthCubit>();
    await context.withAppLoading(
      () => authCubit.registerDeliveryCompany(
        DeliveryCompanyRegistrationData(
          companyName: draft.companyName,
          managerName: draft.managerName,
          phone: phone,
          password: draft.password,
          lat: loc.lat!,
          lng: loc.lng!,
          formattedAddress: loc.formattedAddress,
          city: loc.city,
        ),
      ),
    );
    if (!mounted) return;

    var state = authCubit.state;
    if (state is! AuthenticatedCompany && state is! AuthFailure) {
      // The Firebase auth listener may still be settling.
      try {
        state = await authCubit.stream
            .firstWhere((s) => s is AuthenticatedCompany || s is AuthFailure)
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        if (mounted) context.go(AppRoutes.accountVerifyPhone);
        return;
      }
      if (!mounted) return;
    }
    if (state is AuthFailure) {
      _snack(state.message, AppSnackState.error);
      unawaited(authCubit.dismissFailure());
      return;
    }
    await _sendFirstOtp(phone);
  }

  Future<void> _sendFirstOtp(String phoneE164) async {
    try {
      final result = await context.withAppLoading(
        () => getIt<OtpRepository>().requestOtp(phone: phoneE164),
      );
      if (!mounted) return;
      final ten = egyptTenDigitsFromStored(phoneE164);
      showOtpSentChannelSnack(
        context,
        channel: result.channel,
        phoneDisplay: ten != null && ten.length == 10
            ? '+20 ${formatEgyptTenDigitsDisplay(ten)}'
            : phoneE164,
      );
      context.pushReplacement(
        AppRoutes.verifyOtp,
        extra: VerifyOtpRouteArgs(
          phone: phoneE164,
          requestToken: result.requestToken,
          flow: VerifyOtpFlow.companyPhoneVerification,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _snack(otpOrFirebaseError(e), AppSnackState.error);
      // The verify-phone screen can resend.
      context.go(AppRoutes.accountVerifyPhone);
    }
  }

  void _snack(String message, AppSnackState state) {
    AppSnack.show(
      context,
      message: message.tr,
      state: state,
      icon: state == AppSnackState.error ? ToukhIcons.error : ToukhIcons.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<DeliveryCompanyRegistrationCubit>().state;
    final loc = context.watch<RegistrationCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    final ten = egyptTenDigitsFromStored(draft.phoneE164 ?? '');

    return RegistrationStepScaffold(
      stage: RegistrationStage.review,
      icon: PhosphorIconsDuotone.clipboardText,
      title: AppStrings.Company.reviewTitle,
      subtitle: AppStrings.Company.reviewSubtitle,
      onNext: _submit,
      nextLabelKey: AppStrings.Company.createAccount,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spaceBase,
            AppSizes.spaceBase,
            AppSizes.spaceBase,
            0,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReviewRow(
                icon: ToukhIcons.delivery,
                label: AppStrings.Company.companyName,
                value: draft.companyName,
              ),
              _ReviewRow(
                icon: ToukhIcons.person,
                label: AppStrings.Company.managerName,
                value: draft.managerName,
              ),
              _ReviewRow(
                icon: ToukhIcons.phone,
                label: AppStrings.Auth.phoneNumber,
                value: ten != null && ten.length == 10
                    ? '+20 ${formatEgyptTenDigitsDisplay(ten)}'
                    : draft.phoneNational,
              ),
              _ReviewRow(
                icon: ToukhIcons.location,
                label: AppStrings.Company.location,
                value: loc.formattedAddress,
              ),
              FutureBuilder<ServiceArea?>(
                future: _area,
                builder: (context, snap) => _ReviewRow(
                  icon: ToukhIcons.navigation,
                  label: AppStrings.Company.serviceArea,
                  value: snap.data?.name ?? '…',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondColor),
          SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  label,
                  style: TextStyle(
                    fontSize: AppSizes.fontCaption,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: AppSizes.spaceXs),
                CustomText(
                  value.trim().isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontSize: AppSizes.fontBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
