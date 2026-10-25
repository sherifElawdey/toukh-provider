import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/register_review_edit_sheet.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/settings/presentation/provider_profile_display.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/profile_detail_rows.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Location and operations (hours, delivery, prep time) rows for the
/// settings tab. Owns a [RegistrationCubit] draft seeded from [profile] so
/// the review edit sheets work outside the account details route.
class LocationOperationsSection extends StatefulWidget {
  const LocationOperationsSection({super.key, required this.profile});

  final ProviderProfile profile;

  @override
  State<LocationOperationsSection> createState() =>
      _LocationOperationsSectionState();
}

class _LocationOperationsSectionState extends State<LocationOperationsSection> {
  late final RegistrationCubit _draft =
      RegistrationCubit()..seedFromProfile(widget.profile);

  @override
  void didUpdateWidget(covariant LocationOperationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _draft.seedFromProfile(widget.profile);
    }
  }

  @override
  void dispose() {
    _draft.close();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _draft,
      child: BlocBuilder<RegistrationCubit, RegistrationDraft>(
        builder: (context, draft) {
          final locationValue = () {
            final fromProfile = widget.profile.address?.trim() ?? '';
            if (fromProfile.isNotEmpty) return fromProfile;
            final fromDraft = draft.formattedAddress.trim();
            return fromDraft.isEmpty ? '—' : fromDraft;
          }();

          final operationRows = <ProfileDetailRow>[
            ProfileDetailRow(
              icon: PhosphorIconsRegular.clock,
              labelKey: AppStrings.Registration.hoursTitle,
              value: hoursSummaryFromDraft(draft),
              onTap: () => _openEdit(context, ReviewField.hours),
            ),
            if (deliverySummaryFromDraft(draft) case final delivery?)
              ProfileDetailRow(
                icon: PhosphorIconsRegular.moped,
                labelKey: AppStrings.Registration.deliveryTitle,
                value: delivery,
                onTap: () => _openEdit(context, ReviewField.delivery),
              ),
            if (draft.avgPrepMinutes != null && draft.avgPrepMinutes! > 0)
              ProfileDetailRow(
                icon: PhosphorIconsRegular.timer,
                labelKey: AppStrings.Registration.reviewPrepTime,
                value: '${draft.avgPrepMinutes}',
                onTap: () => _openEdit(context, ReviewField.delivery),
              ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileDetailSection(
                titleKey: AppStrings.Settings.location,
                rows: [
                  ProfileDetailRow(
                    icon: PhosphorIconsRegular.mapPin,
                    labelKey: AppStrings.Registration.mapTitle,
                    value: locationValue,
                    onTap: () => _openEdit(context, ReviewField.location),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceXl),
              ProfileDetailSection(
                titleKey: AppStrings.Settings.operations,
                rows: operationRows,
              ),
            ],
          );
        },
      ),
    );
  }
}
