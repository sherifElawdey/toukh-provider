import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/widgets/auth_brand_header.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) => c is AuthFailure || c is Authenticated,
      listener: (context, state) async {
        if (state is AuthFailure) {
          AppSnack.show(
            context,
            message: state.message,
            state: AppSnackState.error,
            icon: Icons.error_outline_rounded,
          );
          await context.read<AuthCubit>().dismissFailure();
          return;
        }
        if (state is Authenticated) {
          final profile = state.profile;
          final status = profile.status;

          if (status == ProviderAccountStatus.active) {
            // Let the usual splash/onboarding pipeline decide between home
            // and permissions.
            if (!mounted) return;
            context.go(AppRoutes.splash);
            return;
          }

          if (!profile.phoneVerified) {
            // Dedicated verify-phone screen with \"Send OTP\" button.
            if (!mounted) return;
            context.go(AppRoutes.accountVerifyPhone);
            return;
          }

          // Non-active but phone already verified: go to the status screen.
          if (!mounted) return;
          context.go(AppRoutes.postLoginStatus);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (p, c) =>
            (p is AuthLoading) != (c is AuthLoading) || c is AuthLoading,
        builder: (context, authState) {
          final loading = authState is AuthLoading;
          return Scaffold(
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                DecoratedBox(
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
                              title: AppStrings.Auth.welcomeBack,
                              subtitle: AppStrings.Auth.welcomeBackSubtitle,
                            ),
                            SizedBox(height: AppSizes.space3xl),
                            AppPhoneField(
                              controller: _phone,
                              label: AppStrings.Auth.phoneNumber,
                              hint: AppStrings.Auth.phoneHint,
                              invalidTenDigitsMessage:
                                  AppStrings.Auth.invalidPhone,
                              textInputAction: TextInputAction.next,
                            ),
                            SizedBox(height: AppSizes.spaceBase),
                            AppPasswordField(
                              controller: _password,
                              label: AppStrings.Auth.password,
                              textInputAction: TextInputAction.done,
                              validator: (v) => (v == null || v.length < 6)
                                  ? AppStrings.Auth.minPasswordLength
                                  : null,
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: loading
                                    ? null
                                    : () => context.push(
                                          AppRoutes.forgotPassword,
                                        ),
                                child: CustomText(
                                  AppStrings.Auth.forgotPassword,
                                ),
                              ),
                            ),
                            SizedBox(height: AppSizes.spaceMd),
                            FilledButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      if (!_formKey.currentState!.validate()) {
                                        return;
                                      }
                                      final national =
                                          _phone.text.replaceAll(RegExp(r'\D'), '');
                                      context.read<AuthCubit>().signIn(
                                            phone: egyptMobileE164(national),
                                            password: _password.text,
                                          );
                                    },
                              child: CustomText(AppStrings.Auth.signIn),
                            ),
                            SizedBox(height: AppSizes.spaceMd),
                            Center(
                              child: TextButton(
                                onPressed: loading
                                    ? null
                                    : () => context.push(AppRoutes.registerKind),
                                child: CustomText(
                                  AppStrings.Auth.createAccount,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (loading) const AppLoadingOverlay(),
              ],
            ),
          );
        },
      ),
    );
  }
}
