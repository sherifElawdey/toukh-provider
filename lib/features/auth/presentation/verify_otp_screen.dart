import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/twilio/twilio_otp_errors.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/otp_delivery_snack.dart';
import 'package:toukh_provider/features/auth/presentation/reset_password_screen.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:toukh_provider/features/auth/presentation/widgets/otp_pin_row.dart';
import 'package:toukh_provider/features/auth/registration_otp_args_holder.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.args});

  final VerifyOtpRouteArgs args;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otp = TextEditingController();
  final _otpFocus = FocusNode();
  final _otpRepository = getIt<OtpRepository>();

  Timer? _timer;
  int _ticksRemaining = 60;
  int _resendsRemaining = 2;
  bool _resendFullyExhausted = false;
  late String _requestToken;
  bool _registeringAfterVerify = false;

  @override
  void initState() {
    super.initState();
    _requestToken = widget.args.requestToken;
    _startTicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocus.requestFocus();
    });
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_ticksRemaining <= 0) {
        _timer?.cancel();
        setState(() {});
        return;
      }
      setState(() => _ticksRemaining--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_registeringAfterVerify) return;
    final code = _otp.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) return;

    // Password reset verifies once on [ResetPasswordScreen.resetPassword].
    if (widget.args.flow == VerifyOtpFlow.passwordReset) {
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.resetPassword,
        extra: ResetPasswordRouteArgs(
          phone: widget.args.phone,
          requestToken: _requestToken,
          code: code,
        ),
      );
      return;
    }

    try {
      await context.withAppLoading(
        () => _otpRepository.verifyOtp(
          requestToken: _requestToken,
          code: code,
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          message: messageForOtpError(e),
          state: AppSnackState.error,
          icon: PhosphorIconsRegular.password,
        );
      }
      return;
    }

    if (!mounted) return;
    switch (widget.args.flow) {
      case VerifyOtpFlow.passwordReset:
        break;
      case VerifyOtpFlow.registerApplication:
      case VerifyOtpFlow.providerPhoneVerification:
        final authState = context.read<AuthCubit>().state;
        if (authState is! Authenticated) {
          AppSnack.show(
            context,
            message: AppStrings.Auth.registrationDataMissing.tr,
            state: AppSnackState.error,
            icon: ToukhIcons.error,
          );
          context.go(
            widget.args.flow == VerifyOtpFlow.providerPhoneVerification
                ? AppRoutes.accountVerifyPhone
                : AppRoutes.registerKind,
          );
          return;
        }
        // Mark the phone as verified in Firestore, then route based on flow.
        setState(() => _registeringAfterVerify = true);
        await context.read<AuthCubit>().confirmRegistrationOtp();
        if (!mounted) return;
        switch (widget.args.flow) {
          case VerifyOtpFlow.registerApplication:
            getIt<RegistrationOtpArgsHolder>().clear();
            context.go(AppRoutes.requestSubmitted);
          case VerifyOtpFlow.providerPhoneVerification:
            context.go(AppRoutes.splash);
          case VerifyOtpFlow.passwordReset:
            // Handled in the outer switch above.
            break;
        }
    }
  }

  Future<void> _onResendPressed() async {
    if (_ticksRemaining > 0 ||
        _resendsRemaining <= 0 ||
        _resendFullyExhausted) {
      return;
    }
    try {
      final result = await context.withAppLoading(
        () => _otpRepository.requestOtp(phone: widget.args.phone),
      );
      if (!mounted) return;
      setState(() {
        _requestToken = result.requestToken;
        _otp.clear();
        _resendsRemaining--;
        if (_resendsRemaining <= 0) {
          _resendFullyExhausted = true;
          _ticksRemaining = 0;
          _timer?.cancel();
        } else {
          _ticksRemaining = 90;
          _startTicker();
        }
      });
      showOtpSentChannelSnack(
        context,
        channel: result.channel,
        phoneDisplay: _phoneDisplay,
      );
    } catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          message: messageForOtpError(e),
          state: AppSnackState.error,
          icon: ToukhIcons.error,
        );
      }
    }
  }

  String _formatMmSs(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _phoneDisplay {
    final ten = egyptTenDigitsFromStored(widget.args.phone);
    if (ten == null) return widget.args.phone;
    return formatEgyptTenDigitsDisplay(ten);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canResend =
        !_resendFullyExhausted && _resendsRemaining > 0 && _ticksRemaining <= 0;
    final isOtpValid = _otp.text.replaceAll(RegExp(r'\D'), '').length == 6;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => _registeringAfterVerify,
      listener: (context, state) {
        if (state is AuthFailure && _registeringAfterVerify) {
          setState(() => _registeringAfterVerify = false);
          AppSnack.show(
            context,
            message: state.message,
            state: AppSnackState.error,
            icon: ToukhIcons.error,
          );
          context.read<AuthCubit>().dismissFailure();
          return;
        }
        if (state is Unauthenticated && _registeringAfterVerify) {
          setState(() => _registeringAfterVerify = false);
          getIt<RegistrationOtpArgsHolder>().clear();
          context.go(AppRoutes.splash);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (previous, current) =>
            (previous is AuthLoading) != (current is AuthLoading) ||
            current is AuthLoading,
        builder: (context, authState) {
          final loading = authState is AuthLoading;
          final busy = loading || _registeringAfterVerify;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon:  Icon(ToukhIcons.back),
                onPressed: busy ? null : () => context.pop(),
              ),
            ),
            body: Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: AppSizes.screenPadding.copyWith(
                      bottom: AppSizes.space3xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthBrandHeader(
                          title: AppStrings.Auth.otpSentTitle,
                          subtitle: AppStrings.Auth.otpSentSubtitle.trParams({
                            'phone': _phoneDisplay,
                          }),
                        ),
                        SizedBox(height: AppSizes.space3xl),
                        OtpPinRow(
                          controller: _otp,
                          focusNode: _otpFocus,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: AppSizes.space2xl),
                        AppFilledButton(
                          text: AppStrings.Auth.verify,
                          status: busy || !isOtpValid
                              ? AppButtonStatus.disabled
                              : AppButtonStatus.enabled,
                          onTap: _submit,
                        ),
                        SizedBox(height: AppSizes.spaceBase),
                        if (_ticksRemaining > 0)
                          CustomText(
                            AppStrings.Auth.resendCodeIn.trParams({
                              'time': _formatMmSs(_ticksRemaining),
                            }),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppSizes.fontLabel,
                              color: scheme.onSurface.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          AppTextButton(
                            text: AppStrings.Auth.resendCode,
                            status: busy || !canResend
                                ? AppButtonStatus.disabled
                                : AppButtonStatus.enabled,
                            onTap: _onResendPressed,
                          ),
                      ],
                    ),
                  ),
                ),
                if (busy) const AppLoadingOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }
}

