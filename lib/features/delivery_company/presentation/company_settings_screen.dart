import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/constants/legal_urls.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_invite_sheet.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_widgets.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/language_selection_sheet.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_app_version_footer.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_section_title.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Profile tab of a delivery company: same layout as the shop settings, with
/// company details and fleet earnings in place of the shop's profile, wallet,
/// revenues and reviews.
class CompanySettingsScreen extends StatelessWidget {
  const CompanySettingsScreen({super.key, required this.company});

  final DeliveryCompany company;

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      AppSnack.show(
        context,
        message: AppStrings.Settings.legalLaunchFailed,
        state: AppSnackState.error,
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.Settings.deleteAccountTitle),
        content: CustomText(AppStrings.Settings.deleteAccountBody),
        actions: [
          AppTextButton(
            text: AppStrings.Common.cancel,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          AppTextButton(
            text: AppStrings.Settings.deleteAccountContinue,
            color: AppColors.error,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    await _openExternalUrl(context, LegalUrls.deleteAccount);
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.App.logoutConfirmTitle),
        content: CustomText(AppStrings.App.logoutConfirmBody),
        actions: [
          AppTextButton(
            text: AppStrings.Common.cancel,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          AppFilledButton(
            text: AppStrings.Settings.signOut,
            onTap: () => Navigator.of(ctx).pop(true),
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
    final muted = Theme.of(context).colorScheme.onSurface;
    Widget chevron() =>
        Icon(ToukhIcons.chevronRight, color: muted.withValues(alpha: 0.45));

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settings) {
        return ListView(
          padding: AppSizes.screenPadding.copyWith(
            top: AppSizes.spaceLg,
            bottom: AppSizes.space2xl,
          ),
          children: [
            _CompanyHeaderCard(
              company: company,
              onTap: () => context.push(AppRoutes.companyAccount),
            ),
            const SizedBox(height: AppSizes.spaceLg),
            SettingsSectionTitle(labelKey: AppStrings.Company.accountSection),
            const SizedBox(height: AppSizes.spaceSm),
            SettingsTile(
              icon: ToukhIcons.person,
              titleKey: AppStrings.Company.companyDetails,
              trailing: chevron(),
              onTap: () => context.push(AppRoutes.companyAccount),
            ),
            SettingsTile(
              icon: ToukhIcons.wallet,
              titleKey: AppStrings.Company.fleetEarnings,
              trailing: chevron(),
              onTap: () => context.push(AppRoutes.companyEarnings),
            ),
            SettingsTile(
              icon: ToukhIcons.copy,
              titleKey: AppStrings.Company.companyIdShort,
              trailing: chevron(),
              onTap: () => showCompanyInviteSheet(context, company: company),
            ),
            const SizedBox(height: AppSizes.spaceLg),
            SettingsSectionTitle(labelKey: AppStrings.Settings.appearance),
            const SizedBox(height: AppSizes.spaceSm),
            ToukhSettingsThemeTile(
              title: CustomText(AppStrings.Settings.themeMode),
              value: settings.themeMode,
              onChanged: context.read<SettingsCubit>().setThemeMode,
            ),
            const SizedBox(height: AppSizes.spaceXl),
            SettingsSectionTitle(labelKey: AppStrings.Settings.language),
            const SizedBox(height: AppSizes.spaceSm),
            SettingsTile(
              icon: ToukhIcons.language,
              titleKey: AppStrings.Settings.language,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.locale.languageCode == 'ar' ? '🇪🇬' : '🇬🇧',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: AppSizes.spaceXs),
                  CustomText(
                    settings.locale.languageCode == 'ar'
                        ? AppStrings.Common.arabic
                        : AppStrings.Common.english,
                    style: TextStyle(
                      fontSize: AppSizes.fontBody,
                      fontWeight: FontWeight.w500,
                      color: muted.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceXs),
                  Icon(
                    ToukhIcons.chevronDown,
                    color: muted.withValues(alpha: 0.65),
                  ),
                ],
              ),
              onTap: () =>
                  showLanguageSelectionSheet(context, settings: settings),
            ),
            const SizedBox(height: AppSizes.spaceXl),
            SettingsSectionTitle(labelKey: AppStrings.Settings.aboutApp),
            const SizedBox(height: AppSizes.spaceSm),
            SettingsTile(
              icon: ToukhIcons.info,
              titleKey: AppStrings.Settings.aboutApp,
              trailing: chevron(),
              onTap: () => context.push(AppRoutes.aboutApp),
            ),
            const SizedBox(height: AppSizes.spaceXl),
            SettingsSectionTitle(labelKey: AppStrings.Settings.legal),
            const SizedBox(height: AppSizes.spaceSm),
            SettingsTile(
              icon: ToukhIcons.document,
              titleKey: AppStrings.Settings.termsAndConditions,
              trailing: chevron(),
              onTap: () => context.push(AppRoutes.legalTerms),
            ),
            SettingsTile(
              icon: ToukhIcons.privacy,
              titleKey: AppStrings.Settings.privacyPolicy,
              trailing: chevron(),
              onTap: () => context.push(AppRoutes.legalPrivacy),
            ),
            SettingsTile(
              icon: ToukhIcons.info,
              titleKey: AppStrings.Settings.support,
              trailing: chevron(),
              onTap: () => _openExternalUrl(context, LegalUrls.support),
            ),
            SettingsTile(
              icon: ToukhIcons.article,
              titleKey: AppStrings.Settings.declaration,
              trailing: chevron(),
              onTap: () => context.push(AppRoutes.legalDeclaration),
            ),
            const SizedBox(height: AppSizes.spaceLg),
            SettingsTile(
              icon: ToukhIcons.delete,
              iconColor: AppColors.error,
              titleKey: AppStrings.Settings.deleteAccount,
              onTap: () => _confirmDeleteAccount(context),
            ),
            const SizedBox(height: AppSizes.spaceXl),
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
                        ToukhIcons.logout,
                        color: AppColors.error,
                        size: AppSizes.iconLg,
                      ),
                      const SizedBox(width: AppSizes.spaceSm),
                      CustomText(
                        AppStrings.Settings.signOut,
                        style: const TextStyle(
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
  }
}

class _CompanyHeaderCard extends StatelessWidget {
  const _CompanyHeaderCard({required this.company, required this.onTap});

  final DeliveryCompany company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);
    final initial = company.companyName.trim().isEmpty
        ? '?'
        : company.companyName.trim().characters.first.toUpperCase();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: ToukhCard.decoration(context),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.secondColor.withValues(alpha: 0.15),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondColor,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      company.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: AppSizes.fontTitle,
                      ),
                    ),
                    CustomText(
                      [
                        company.managerName,
                        company.phone,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                    const SizedBox(height: AppSizes.spaceXs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        CompanyChip(
                          label: AppStrings.Company.statusActive,
                          color: AppColors.success,
                        ),
                        if (company.serviceAreaName != null)
                          CompanyChip(
                            label: company.serviceAreaName!,
                            color: AppColors.secondColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(ToukhIcons.chevronRight, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
