import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

/// Shown when the user is signed in but the Firestore provider document is
/// still missing or not yet readable (replaces an endless splash).
class ProfilePendingScreen extends StatelessWidget {
  const ProfilePendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
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
          child: Padding(
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.space3xl,
              bottom: AppSizes.space2xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: ToukhServiceLogo(
                    size: 88,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                SizedBox(height: AppSizes.spaceXl),
                const Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
                SizedBox(height: AppSizes.space2xl),
                CustomText(
                  AppStrings.Auth.profilePendingTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontHeadline,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondColor,
                  ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                CustomText(
                  AppStrings.Auth.profilePendingSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontBody,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const Spacer(),
                // AppFilledButton(
                //   text: AppStrings.AccountStatus.signOut,
                //   onTap: () => context.read<AuthCubit>().signOut(),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
