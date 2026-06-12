import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/register_review_edit_sheet.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/register_review_tile.dart';
import 'package:toukh_provider/features/settings/presentation/provider_profile_display.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_section_title.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  void _seedDraft(ProviderProfile profile) {
    context.read<RegistrationCubit>().seedFromProfile(profile);
  }

  void _openEdit(BuildContext context, ReviewField field) {
    unawaited(
      showRegisterReviewEditSheet(
        context,
        field: field,
        onPersist: (draft) =>
            context.read<AuthCubit>().updateProfileField(field, draft),
      ),
    );
  }

  void _showLockedSnack(BuildContext context) {
    AppSnack.show(
      context,
      message: AppStrings.Settings.fieldLocked.tr,
      state: AppSnackState.alert,
      icon: ToukhIcons.lock,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, next) =>
          next is Authenticated &&
          (prev is! Authenticated || prev.profile != next.profile),
      listener: (context, state) {
        if (state is Authenticated) {
          _seedDraft(state.profile);
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: Icon(ToukhIcons.back),
                  onPressed: () => context.pop(),
                ),
                title: CustomText(AppStrings.Settings.accountDetails),
              ),
              body: const Center(child: AppLoadingMark()),
            );
          }

          final profile = authState.profile;
          final draft = context.watch<RegistrationCubit>().state;
          final scheme = Theme.of(context).colorScheme;
          final locale = Localizations.localeOf(context).languageCode;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(ToukhIcons.back),
                onPressed: () => context.pop(),
              ),
              title: CustomText(AppStrings.Settings.accountDetails),
            ),
            body: ListView(
              padding: AppSizes.screenPadding.copyWith(
                top: AppSizes.spaceMd,
                bottom: AppSizes.space2xl,
              ),
              children: [
                _AccountDetailsHero(profile: profile),
                SizedBox(height: AppSizes.spaceXl),
                SettingsSectionTitle(
                  labelKey: AppStrings.Settings.businessInfo,
                ),
                SizedBox(height: AppSizes.spaceSm),
                RegisterReviewTile(
                  icon: ToukhIcons.store,
                  titleKey: AppStrings.Registration.reviewBusinessType,
                  value: draft.kind == null
                      ? '—'
                      : providerKindLabelKey(draft.kind!).tr,
                  scheme: scheme,
                  onTap: () => _showLockedSnack(context),
                ),
                if (categoryEntryFromDraft(draft) case final cat?) ...[
                  RegisterReviewTile(
                    icon: PhosphorIconsRegular.tag,
                    titleKey: cat.$1,
                    value: cat.$2,
                    scheme: scheme,
                    onTap: () => _showLockedSnack(context),
                  ),
                ],
                RegisterReviewTile(
                  icon: PhosphorIconsRegular.identificationBadge,
                  titleKey: AppStrings.Registration.brandName,
                  value: draft.name.trim().isEmpty ? '—' : draft.name.trim(),
                  scheme: scheme,
                  onTap: () => _openEdit(context, ReviewField.profile),
                ),
                if (draft.description.trim().isNotEmpty)
                  RegisterReviewTile(
                    icon: PhosphorIconsRegular.notepad,
                    titleKey: AppStrings.Registration.description,
                    value: draft.description.trim(),
                    scheme: scheme,
                    onTap: () => _openEdit(context, ReviewField.profile),
                  ),
                SizedBox(height: AppSizes.spaceLg),
                SettingsSectionTitle(
                  labelKey: AppStrings.Settings.contactInfo,
                ),
                SizedBox(height: AppSizes.spaceSm),
                RegisterReviewTile(
                  icon: ToukhIcons.phone,
                  titleKey: AppStrings.Auth.phoneNumber,
                  value: formatProviderPhone(profile.phone),
                  scheme: scheme,
                  onTap: () => _showLockedSnack(context),
                ),
                SizedBox(height: AppSizes.spaceLg),
                SettingsSectionTitle(labelKey: AppStrings.Settings.location),
                SizedBox(height: AppSizes.spaceSm),
                RegisterReviewTile(
                  icon: ToukhIcons.location,
                  titleKey: AppStrings.Registration.mapTitle,
                  value: draft.formattedAddress.trim().isEmpty
                      ? '—'
                      : draft.formattedAddress.trim(),
                  scheme: scheme,
                  onTap: () => _openEdit(context, ReviewField.location),
                ),
                SizedBox(height: AppSizes.spaceLg),
                SettingsSectionTitle(
                  labelKey: AppStrings.Settings.operations,
                ),
                SizedBox(height: AppSizes.spaceSm),
                RegisterReviewTile(
                  icon: ToukhIcons.clock,
                  titleKey: AppStrings.Registration.hoursTitle,
                  value: hoursSummaryFromDraft(draft),
                  scheme: scheme,
                  onTap: () => _openEdit(context, ReviewField.hours),
                ),
                if (deliverySummaryFromDraft(draft) case final delivery?) ...[
                  RegisterReviewTile(
                    icon: ToukhIcons.delivery,
                    titleKey: AppStrings.Registration.deliveryTitle,
                    value: delivery,
                    scheme: scheme,
                    onTap: () => _openEdit(context, ReviewField.delivery),
                  ),
                ],
                if (draft.avgPrepMinutes != null && draft.avgPrepMinutes! > 0)
                  RegisterReviewTile(
                    icon: ToukhIcons.clock,
                    titleKey: AppStrings.Registration.reviewPrepTime,
                    value: '${draft.avgPrepMinutes}',
                    scheme: scheme,
                    onTap: () => _openEdit(context, ReviewField.delivery),
                  ),
                SizedBox(height: AppSizes.spaceLg),
                SettingsSectionTitle(
                  labelKey: AppStrings.Settings.accountInfo,
                ),
                SizedBox(height: AppSizes.spaceSm),
                RegisterReviewTile(
                  icon: ToukhIcons.calendar,
                  titleKey: AppStrings.Settings.memberSince,
                  value: formatMemberSince(profile.createdAt, locale),
                  scheme: scheme,
                ),
                RegisterReviewTile(
                  icon: profile.phoneVerified
                      ? ToukhIcons.success
                      : ToukhIcons.warning,
                  titleKey: AppStrings.Settings.phoneVerified,
                  value: profile.phoneVerified
                      ? AppStrings.Common.success.tr
                      : AppStrings.Settings.statusUnverified.tr,
                  scheme: scheme,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountDetailsHero extends StatelessWidget {
  const _AccountDetailsHero({required this.profile});

  final ProviderProfile profile;

  Color _statusColor(ProviderAccountStatus status) {
    switch (status) {
      case ProviderAccountStatus.active:
        return AppColors.success;
      case ProviderAccountStatus.pending:
      case ProviderAccountStatus.unverified:
        return AppColors.warning;
      case ProviderAccountStatus.blocked:
      case ProviderAccountStatus.deleted:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = profile.brandImageUrl;
    final statusColor = _statusColor(profile.status);

    return Material(
      elevation: 0,
      color: AppColors.appColor.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceLg),
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: 88,
                height: 88,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          PhosphorIconsRegular.storefront,
                          size: 40,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                      )
                    : ColoredBox(
                        color: AppColors.thirdColor.withValues(alpha: 0.5),
                        child: Icon(
                          PhosphorIconsRegular.storefront,
                          size: 40,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
              ),
            ),
            SizedBox(height: AppSizes.spaceMd),
            CustomText(
              profile.name.trim().isEmpty ? '—' : profile.name.trim(),
              style: TextStyle(
                fontSize: AppSizes.fontHeadline,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.spaceXs),
            CustomText(
              serviceTypeSubtitle(profile),
              style: TextStyle(
                fontSize: AppSizes.fontLabel,
                fontWeight: FontWeight.w600,
                color: AppColors.secondColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSizes.spaceMd),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd,
                vertical: AppSizes.spaceXs,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: CustomText(
                accountStatusLabelKey(profile.status).tr,
                style: TextStyle(
                  fontSize: AppSizes.fontLabel,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
