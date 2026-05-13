import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/language_selection_sheet.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_app_version_footer.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_profile_header_card.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_section_title.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_theme_toggle.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.App.logoutConfirmTitle),
        content: CustomText(AppStrings.App.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: CustomText(AppStrings.Common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: CustomText(AppStrings.Settings.signOut),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthCubit>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, auth) {
            return ListView(
              padding: AppSizes.screenPadding.copyWith(
                top: AppSizes.spaceLg,
                bottom: AppSizes.space2xl,
              ),
              children: [
                Center(
                  child: ToukhServiceLogo(
                    size: 64,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                SizedBox(height: AppSizes.spaceLg),
                if (auth is Authenticated) ...[
                  SettingsProfileHeaderCard(
                    profile: auth.profile,
                    onTap: () => AppSnack.show(
                      context,
                      message: AppStrings.Settings.editProfileComingSoon,
                      state: AppSnackState.alert,
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceLg),
                ],
                SettingsTile(
                  icon: Icons.history_rounded,
                  titleKey: AppStrings.Settings.ordersHistory,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                  onTap: () => context.go(AppRoutes.orders),
                ),
                SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  titleKey: AppStrings.Settings.wallet,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                  onTap: () => AppSnack.show(
                    context,
                    message: AppStrings.Settings.walletComingSoon,
                    state: AppSnackState.alert,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                SizedBox(height: AppSizes.spaceLg),
                SettingsSectionTitle(labelKey: AppStrings.Settings.appearance),
                SizedBox(height: AppSizes.spaceSm),
                SettingsThemeToggle(
                  value: settings.themeMode,
                  onChanged: context.read<SettingsCubit>().setThemeMode,
                ),
                SizedBox(height: AppSizes.spaceXl),
                SettingsSectionTitle(labelKey: AppStrings.Settings.language),
                SizedBox(height: AppSizes.spaceSm),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  titleKey: AppStrings.Settings.language,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        settings.locale.languageCode == 'ar' ? '🇪🇬' : '🇬🇧',
                        style: const TextStyle(fontSize: 20),
                      ),
                      SizedBox(width: AppSizes.spaceXs),
                      CustomText(
                        settings.locale.languageCode == 'ar'
                            ? AppStrings.Common.arabic
                            : AppStrings.Common.english,
                        style: TextStyle(
                          fontSize: AppSizes.fontBody,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                      SizedBox(width: AppSizes.spaceXs),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ],
                  ),
                  onTap: () => showLanguageSelectionSheet(
                    context,
                    settings: settings,
                  ),
                ),
                SizedBox(height: AppSizes.spaceXl),
                SettingsSectionTitle(labelKey: AppStrings.Settings.legal),
                SizedBox(height: AppSizes.spaceSm),
                SettingsTile(
                  icon: Icons.description_outlined,
                  titleKey: AppStrings.Settings.termsAndConditions,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                  onTap: () => context.push(AppRoutes.legalTerms),
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  titleKey: AppStrings.Settings.privacyPolicy,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                  onTap: () => context.push(AppRoutes.legalPrivacy),
                ),
                SettingsTile(
                  icon: Icons.article_outlined,
                  titleKey: AppStrings.Settings.declaration,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                  ),
                  onTap: () => context.push(AppRoutes.legalDeclaration),
                ),
                SizedBox(height: AppSizes.spaceXl),
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    onTap: () => _confirmSignOut(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spaceLg,
                        vertical: AppSizes.spaceSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: AppSizes.iconLg,
                          ),
                          SizedBox(width: AppSizes.spaceSm),
                          CustomText(
                            AppStrings.Settings.signOut,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: AppSizes.fontTitle,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Center(child: SettingsAppVersionFooter()),
              ],
            );
          },
        );
      },
    );
  }
}
