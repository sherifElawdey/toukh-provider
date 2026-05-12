import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/utils/phone_auth_helpers.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_profile_repository.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpRepository = getIt<OtpRepository>();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final national = _phone.text.replaceAll(RegExp(r'\D'), '');
    final phone = egyptMobileE164(national);
    final digits = displayDigits(phone);
    final repo = getIt<ProviderProfileRepository>();
    final registered = await repo.existsByPhone(digits);
    if (!mounted) return;
    if (!registered) {
      AppSnack.show(
        context,
        message: AppStrings.Auth.phoneNotRegistered.tr,
        state: AppSnackState.error,
        icon: Icons.person_off_outlined,
      );
      return;
    }
    try {
      final token = await context.withAppLoading(
        () => _otpRepository.requestOtp(phone: phone),
      );
      if (!mounted) return;
      context.push(
        AppRoutes.verifyOtp,
        extra: VerifyOtpRouteArgs(
          phone: phone,
          requestToken: token,
          flow: VerifyOtpFlow.passwordReset,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: '$e',
        state: AppSnackState.error,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthBrandHeader(
                    title: AppStrings.Auth.forgotPasswordTitle,
                    subtitle: AppStrings.Auth.forgotPasswordSubtitle,
                  ),
                  SizedBox(height: AppSizes.space3xl),
                  AppPhoneField(
                    controller: _phone,
                    label: AppStrings.Auth.phoneNumber,
                    hint: AppStrings.Auth.phoneHint,
                    invalidTenDigitsMessage: AppStrings.Auth.invalidPhone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _sendOtp(),
                  ),
                  SizedBox(height: AppSizes.space2xl),
                  FilledButton(
                    onPressed: _sendOtp,
                    child: CustomText(AppStrings.Auth.sendOtp),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
