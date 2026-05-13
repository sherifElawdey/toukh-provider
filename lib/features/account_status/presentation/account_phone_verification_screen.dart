import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/otp_delivery_snack.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Phone OTP entry for signed-in providers with `unverified` status and
/// `phoneVerified == false`.
class AccountPhoneVerificationScreen extends StatelessWidget {
  const AccountPhoneVerificationScreen({super.key});

  static String? _phoneE164FromProfile(String storedPhone) {
    final ten = egyptTenDigitsFromStored(storedPhone);
    if (ten != null && ten.length == 10) {
      final e164 = egyptMobileE164(ten);
      return e164.isEmpty ? null : e164;
    }
    final raw = toFirebaseE164(storedPhone);
    return raw.isEmpty ? null : raw;
  }

  Future<void> _sendOtp(BuildContext context, Authenticated auth) async {
    final phone = _phoneE164FromProfile(auth.profile.phone);
    if (phone == null) {
      AppSnack.show(
        context,
        message: AppStrings.AccountStatus.verifyPhoneInvalidStoredPhone.tr,
        state: AppSnackState.error,
        icon: Icons.phone_disabled_rounded,
      );
      return;
    }

    final otpRepository = getIt<OtpRepository>();
    try {
      final result = await context.withAppLoading(
        () => otpRepository.requestOtp(phone: phone),
      );
      if (!context.mounted) return;
      final ten = egyptTenDigitsFromStored(phone);
      final phoneDisplay = ten != null && ten.length == 10
          ? '+20 ${formatEgyptTenDigitsDisplay(ten)}'
          : phone;
      showOtpSentChannelSnack(
        context,
        channel: result.channel,
        phoneDisplay: phoneDisplay,
      );
      await context.push(
        AppRoutes.verifyOtp,
        extra: VerifyOtpRouteArgs(
          phone: phone,
          requestToken: result.requestToken,
          flow: VerifyOtpFlow.providerPhoneVerification,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnack.show(
          context,
          message: '$e',
          state: AppSnackState.error,
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(body: SizedBox.shrink());
        }
        final profile = authState.profile;
        final nameLabel = profile.displayName.trim().isEmpty
            ? AppStrings.AccountStatus.verifyPhoneFallbackName.tr
            : profile.displayName.trim();
        final masked =
            maskEgyptNationalPhoneLastThree(profile.phone);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: () => context.read<AuthCubit>().signOut(),
                child: CustomText(AppStrings.AccountStatus.signOut),
              ),
            ],
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.thirdColor.withValues(alpha: 0.55),
                  AppColors.surface,
                  AppColors.surface,
                ],
                stops: const [0.0, 0.38, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: AppSizes.screenPadding.copyWith(
                  top: AppSizes.space2xl,
                  bottom: AppSizes.space3xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ToukhServiceLogo(size: AppSizes.logoAuth),
                    SizedBox(height: AppSizes.spaceXl),
                    CustomText(
                      AppStrings.AccountStatus.verifyPhoneTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSizes.fontHeadline,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondColor,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceMd),
                    Text(
                      AppStrings.AccountStatus.verifyPhoneBody.trParams({
                        'name': nameLabel,
                        'phone': masked,
                      }),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.family,
                        fontSize: AppSizes.fontBody,
                        height: 1.45,
                        color: scheme.onSurface.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSizes.space3xl),
                    FilledButton(
                      onPressed: () => _sendOtp(context, authState),
                      child: CustomText(AppStrings.Auth.sendOtp),
                    ),
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
