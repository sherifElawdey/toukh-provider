import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/reset_password_screen.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/features/auth/presentation/widgets/auth_brand_header.dart';
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
          message: '$e',
          state: AppSnackState.error,
          icon: Icons.pin_outlined,
        );
      }
      return;
    }

    if (!mounted) return;
    switch (widget.args.flow) {
      case VerifyOtpFlow.passwordReset:
        context.pushReplacement(
          AppRoutes.resetPassword,
          extra: ResetPasswordRouteArgs(
            phone: widget.args.phone,
            requestToken: _requestToken,
            code: code,
          ),
        );
      case VerifyOtpFlow.registerApplication:
      case VerifyOtpFlow.providerPhoneVerification:
        final authState = context.read<AuthCubit>().state;
        if (authState is! Authenticated) {
          AppSnack.show(
            context,
            message: AppStrings.Auth.registrationDataMissing.tr,
            state: AppSnackState.error,
            icon: Icons.error_outline_rounded,
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
      final token = await context.withAppLoading(
        () => _otpRepository.requestOtp(phone: widget.args.phone),
      );
      if (!mounted) return;
      setState(() {
        _requestToken = token;
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
    } catch (e) {
      if (mounted) {
        AppSnack.show(
          context,
          message: '$e',
          state: AppSnackState.error,
          icon: Icons.error_outline_rounded,
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
            icon: Icons.error_outline_rounded,
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                        _OtpPinRow(
                          controller: _otp,
                          focusNode: _otpFocus,
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: AppSizes.space2xl),
                        FilledButton(
                          onPressed: busy || !isOtpValid ? null : _submit,
                          child: CustomText(AppStrings.Auth.verify),
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
                          TextButton(
                            onPressed: busy || !canResend ? null : _onResendPressed,
                            child: CustomText(AppStrings.Auth.resendCode),
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

class _OtpPinRow extends StatelessWidget {
  const _OtpPinRow({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: AppColors.inputTextHidden,
                height: 1.2,
                letterSpacing: 18,
              ),
              cursorColor: AppColors.appColor,
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              autofillHints: const [AutofillHints.oneTimeCode],
            ),
          ),
          ListenableBuilder(
            listenable: Listenable.merge([controller, focusNode]),
            builder: (context, _) {
              return IgnorePointer(
                child: Row(
                  children: List.generate(6, (i) {
                    final has = i < controller.text.length;
                    final ch = has ? controller.text[i] : '';
                    final active =
                        focusNode.hasFocus && i == controller.text.length;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.fieldFill(context),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            border: Border.all(
                              color: active
                                  ? AppColors.appColor
                                  : AppColors.secondColor.withValues(
                                      alpha: 0.22,
                                    ),
                              width: active ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: CustomText(
                              ch,
                              style: TextStyle(
                                fontSize: AppSizes.fontHeadline,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
