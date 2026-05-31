import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/twilio/twilio_otp_errors.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

final class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({
    required this.phone,
    required this.requestToken,
    required this.code,
  });

  final String phone;
  final String requestToken;
  final String code;
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.args});

  final ResetPasswordRouteArgs args;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpRepository = getIt<OtpRepository>();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.withAppLoading(
        () => _otpRepository.resetPassword(
          phone: widget.args.phone,
          requestToken: widget.args.requestToken,
          code: widget.args.code,
          newPassword: _password.text,
        ),
      );
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Common.success,
        state: AppSnackState.success,
        icon: Icons.check_circle_outline,
      );
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: messageForOtpError(e),
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
                    title: AppStrings.Auth.resetPasswordTitle,
                    subtitle: AppStrings.Auth.resetPasswordSubtitle,
                  ),
                  SizedBox(height: AppSizes.space3xl),
                  AppPasswordField(
                    controller: _password,
                    label: AppStrings.Auth.newPassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => (v == null || v.length < 6)
                        ? AppStrings.Auth.minPasswordLength
                        : null,
                  ),
                  SizedBox(height: AppSizes.spaceBase),
                  AppPasswordField(
                    controller: _confirm,
                    label: AppStrings.Auth.confirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => (v != _password.text)
                        ? AppStrings.Auth.passwordsDoNotMatch
                        : null,
                  ),
                  SizedBox(height: AppSizes.space2xl),
                  AppFilledButton(
                    text: AppStrings.Auth.savePassword,
                    onTap: _submit,
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
