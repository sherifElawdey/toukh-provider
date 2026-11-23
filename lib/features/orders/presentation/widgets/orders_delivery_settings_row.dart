import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/register_review_edit_sheet.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/settings/presentation/provider_profile_display.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// The store's delivery setup at the top of the orders tab; opens the same
/// editor as the delivery row in settings.
class OrdersDeliverySettingsRow extends StatefulWidget {
  const OrdersDeliverySettingsRow({super.key, required this.profile});

  final ProviderProfile profile;

  @override
  State<OrdersDeliverySettingsRow> createState() =>
      _OrdersDeliverySettingsRowState();
}

class _OrdersDeliverySettingsRowState extends State<OrdersDeliverySettingsRow> {
  late final RegistrationCubit _draft = RegistrationCubit()
    ..seedFromProfile(widget.profile);

  @override
  void didUpdateWidget(covariant OrdersDeliverySettingsRow oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppSizes.radiusMd);
    return BlocProvider.value(
      value: _draft,
      child: BlocBuilder<RegistrationCubit, RegistrationDraft>(
        builder: (context, draft) {
          final summary = deliverySummaryFromDraft(draft);
          if (summary == null) return const SizedBox.shrink();
          return Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: () => unawaited(
                showRegisterReviewEditSheet(
                  context,
                  field: ReviewField.delivery,
                  onPersist: (draft) => context
                      .read<AuthCubit>()
                      .updateProfileField(ReviewField.delivery, draft),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceMd,
                  vertical: AppSizes.spaceSm,
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.moped,
                      size: 20,
                      color: AppColors.secondColor,
                    ),
                    const SizedBox(width: AppSizes.spaceSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            AppStrings.Registration.deliveryTitle,
                            style: TextStyle(
                              fontSize: AppSizes.fontCaption,
                              color: AppColors.muted(context),
                            ),
                          ),
                          CustomText(
                            summary,
                            maxLines: 2,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      PhosphorIconsRegular.pencilSimple,
                      size: 18,
                      color: AppColors.muted(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
