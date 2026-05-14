import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class UnverifiedScreen extends StatelessWidget {
  const UnverifiedScreen({super.key});

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
                    size: 96,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                SizedBox(height: AppSizes.spaceXl),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warning.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.hourglass_empty_rounded,
                    size: 64,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: AppSizes.space2xl),
                CustomText(
                  AppStrings.AccountStatus.unverifiedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontHeadline,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondColor,
                  ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                CustomText(
                  AppStrings.AccountStatus.unverifiedSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontBody,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const Spacer(),
                AppFilledButton(
                  text: AppStrings.AccountStatus.signOut,
                  onTap: () => context.read<AuthCubit>().signOut(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
