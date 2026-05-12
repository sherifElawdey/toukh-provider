import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (p, c) =>
          c is Authenticated &&
          c.profile.status == ProviderAccountStatus.active,
      listener: (context, state) {
        context.go(AppRoutes.splash);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: ToukhServiceLogo(
                    size: 96,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                SizedBox(height: AppSizes.spaceXl),
                CustomText(
                  AppStrings.Pending.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontHeadline,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                CustomText(
                  AppStrings.Pending.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontBody,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => context.read<AuthCubit>().signOut(),
                  child: CustomText(AppStrings.AccountStatus.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
