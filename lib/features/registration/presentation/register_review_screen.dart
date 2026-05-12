import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/features/auth/registration_otp_args_holder.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterReviewScreen extends StatefulWidget {
  const RegisterReviewScreen({super.key});

  @override
  State<RegisterReviewScreen> createState() => _RegisterReviewScreenState();
}

class _RegisterReviewScreenState extends State<RegisterReviewScreen> {
  final _otpRepository = getIt<OtpRepository>();
  bool _otpRequested = false;

  Future<void> _maybeSendOtp(String phoneE164) async {
    try {
      final token = await _otpRepository.requestOtp(phone: phoneE164);
      if (!mounted) return;
      final args = VerifyOtpRouteArgs(
        phone: phoneE164,
        requestToken: token,
        flow: VerifyOtpFlow.registerApplication,
      );
      getIt<RegistrationOtpArgsHolder>().stashForRegistration(args);
      await context.push(AppRoutes.verifyOtp, extra: args);
    } catch (e) {
      _otpRequested = false;
      if (mounted) {
        AppSnack.show(
          context,
          message: '$e',
          state: AppSnackState.error,
          icon: Icons.sms_failed_outlined,
        );
      }
    }
  }

  String? _phoneE164FromDraft(RegistrationDraft d) {
    final raw = d.phoneNational.replaceAll(RegExp(r'\D'), '');
    final ten =
        raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
    if (ten.length != 10) return null;
    final e164 = egyptMobileE164(ten);
    return e164.isEmpty ? null : e164;
  }

  Future<void> _submit() async {
    final draft = context.read<RegistrationCubit>().state;
    final data = draft.toSubmitData();
    if (data == null) {
      AppSnack.show(
        context,
        message: AppStrings.Auth.registrationDataMissing.tr,
        state: AppSnackState.error,
        icon: Icons.error_outline_rounded,
      );
      return;
    }
    await context.withAppLoading(() async {
      await context.read<AuthCubit>().registerProviderInitial(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;
    final data = draft.toSubmitData();
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) {
        if (c is AuthFailure) return true;
        if (c is Authenticated &&
            c.profile.status == ProviderAccountStatus.pending &&
            !c.profile.phoneVerified &&
            !_otpRequested) {
          return true;
        }
        return false;
      },
      listener: (context, state) async {
        if (state is AuthFailure) {
          AppSnack.show(
            context,
            message: state.message,
            state: AppSnackState.error,
            icon: Icons.error_outline_rounded,
          );
          context.read<AuthCubit>().dismissFailure();
          return;
        }
        if (state is Authenticated &&
            state.profile.status == ProviderAccountStatus.pending &&
            !state.profile.phoneVerified &&
            !_otpRequested) {
          final phone = _phoneE164FromDraft(
            context.read<RegistrationCubit>().state,
          );
          if (phone == null) return;
          _otpRequested = true;
          await _maybeSendOtp(phone);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          title: CustomText(AppStrings.Registration.reviewTitle),
        ),
        body: Padding(
          padding: AppSizes.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Center(
                      child: ToukhServiceLogo(
                        size: 56,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceMd),
                    ListTile(
                      title: CustomText(AppStrings.Registration.brandName.tr),
                      subtitle: CustomText(draft.name.isEmpty ? '—' : draft.name),
                    ),
                    ListTile(
                      title: CustomText(AppStrings.Auth.phoneNumber.tr),
                      subtitle: CustomText(draft.phoneNational),
                    ),
                    ListTile(
                      title: CustomText(AppStrings.Registration.mapTitle.tr),
                      subtitle: CustomText(
                        draft.formattedAddress.isEmpty
                            ? '—'
                            : draft.formattedAddress,
                      ),
                    ),
                  ],
                ),
              ),
              RegistrationStepNavFooter(
                onBack: () => context.pop(),
                onNext: () => unawaited(_submit()),
                nextLabelKey: AppStrings.Registration.submit,
                nextEnabled: data != null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
