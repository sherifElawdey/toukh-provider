import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/register_review_edit_sheet.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/settings/presentation/provider_profile_display.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/editable_provider_avatar.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/profile_detail_rows.dart';
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
          final locale = Localizations.localeOf(context).languageCode;

          final businessRows = <ProfileDetailRow>[
            ProfileDetailRow(
              icon: PhosphorIconsRegular.storefront,
              labelKey: AppStrings.Registration.reviewBusinessType,
              value: draft.kind == null
                  ? '—'
                  : providerKindLabelKey(draft.kind!).tr,
              locked: true,
              onTap: () => _showLockedSnack(context),
            ),
            if (categoryEntryFromDraft(draft) case final cat?)
              ProfileDetailRow(
                icon: PhosphorIconsRegular.squaresFour,
                labelKey: cat.$1,
                value: cat.$2,
                locked: true,
                onTap: () => _showLockedSnack(context),
              ),
            if (draft.kind == ServiceType.otherShops) ...[
              ProfileDetailRow(
                icon: PhosphorIconsRegular.tag,
                labelKey: AppStrings.Registration.otherShopReviewTitle,
                value: otherShopChoiceLabel(
                  draft.otherShopCategoryId,
                  draft.otherShopTypeIds,
                  locale,
                ),
                onTap: () => _openEdit(context, ReviewField.otherShop),
              ),
              ProfileDetailRow(
                icon: PhosphorIconsRegular.chatCircleText,
                labelKey: AppStrings.Registration.orderModeReviewTitle,
                value: draft.orderMode == ProviderOrderMode.customRequests
                    ? AppStrings.Registration.orderModeCustom.tr
                    : AppStrings.Registration.orderModeMenu.tr,
                onTap: () => _openEdit(context, ReviewField.otherShop),
              ),
            ],
            ProfileDetailRow(
              icon: PhosphorIconsRegular.tag,
              labelKey: AppStrings.Registration.brandName,
              value: draft.name.trim().isEmpty ? '—' : draft.name.trim(),
              onTap: () => _openEdit(context, ReviewField.profile),
            ),
            if (draft.description.trim().isNotEmpty)
              ProfileDetailRow(
                icon: PhosphorIconsRegular.textAlignLeft,
                labelKey: AppStrings.Registration.description,
                value: draft.description.trim(),
                onTap: () => _openEdit(context, ReviewField.profile),
              ),
            if (draft.kind == ServiceType.homeService)
              ProfileDetailRow(
                icon: PhosphorIconsRegular.listChecks,
                labelKey: AppStrings.Registration.preServiceQuestionsTitle,
                value: draft.preServiceQuestions.isEmpty
                    ? AppStrings.Registration.preServiceQuestionsNone.tr
                    : AppStrings.Registration.preServiceQuestionsCount.trParams(
                        {'count': '${draft.preServiceQuestions.length}'},
                      ),
                onTap: () =>
                    _openEdit(context, ReviewField.preServiceQuestions),
              ),
          ];

          final contactRows = <ProfileDetailRow>[
            ProfileDetailRow(
              icon: PhosphorIconsRegular.phone,
              labelKey: AppStrings.Auth.phoneNumber,
              value: formatProviderPhone(profile.phone),
              locked: true,
              onTap: () => _showLockedSnack(context),
            ),
            ProfileDetailRow(
              icon: PhosphorIconsRegular.addressBook,
              labelKey: AppStrings.Settings.brandInfo,
              value: brandInfoSummary(profile.brandInfo),
              onTap: () => context.push(AppRoutes.brandInfo),
            ),
          ];

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(ToukhIcons.back),
                onPressed: () => context.pop(),
              ),
              title: CustomText(AppStrings.Settings.accountDetails),
            ),
            body: ToukhRefresh(
              onRefresh: context.read<AuthCubit>().refreshProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSizes.screenPadding.copyWith(
                  top: AppSizes.spaceMd,
                  bottom: AppSizes.space2xl,
                ),
                children: [
                  _ProfileHeader(profile: profile),
                  SizedBox(height: AppSizes.spaceXl),
                  ProfileDetailSection(
                    titleKey: AppStrings.Settings.businessInfo,
                    rows: businessRows,
                  ),
                  SizedBox(height: AppSizes.spaceXl),
                  ProfileDetailSection(
                    titleKey: AppStrings.Settings.contactInfo,
                    rows: contactRows,
                  ),
                  SizedBox(height: AppSizes.spaceXl),
                  ProfileDetailSection(
                    titleKey: AppStrings.Settings.accountInfo,
                    rows: [
                      ProfileDetailRow(
                        icon: PhosphorIconsRegular.calendarBlank,
                        labelKey: AppStrings.Settings.memberSince,
                        value: formatMemberSince(profile.createdAt, locale),
                      ),
                      ProfileDetailRow(
                        icon: PhosphorIconsRegular.sealCheck,
                        labelKey: AppStrings.Settings.phoneVerified,
                        value: profile.phoneVerified
                            ? AppStrings.Common.success.tr
                            : AppStrings.Settings.statusUnverified.tr,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

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
    final statusColor = _statusColor(profile.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        EditableProviderAvatar(imageUrl: profile.brandImageUrl, size: 72),
        SizedBox(width: AppSizes.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                profile.name.trim().isEmpty ? '—' : profile.name.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppSizes.fontTitle,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: AppSizes.spaceXs),
              CustomText(
                serviceTypeSubtitle(profile),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppSizes.fontLabel,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondColor,
                ),
              ),
              SizedBox(height: AppSizes.spaceSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
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
      ],
    );
  }
}
