import 'package:flutter/material.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_widgets.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Couriers join by entering the company ID in the delivery app, then the
/// company accepts the request; this sheet explains that and shares the ID.
Future<void> showCompanyInviteSheet(
  BuildContext context, {
  required DeliveryCompany company,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXl),
      ),
    ),
    builder: (_) => _CompanyInviteSheet(company: company),
  );
}

class _CompanyInviteSheet extends StatelessWidget {
  const _CompanyInviteSheet({required this.company});

  final DeliveryCompany company;

  @override
  Widget build(BuildContext context) {
    final steps = [
      AppStrings.Company.inviteStep1,
      AppStrings.Company.inviteStep2,
      AppStrings.Company.inviteStep3,
    ];
    return SingleChildScrollView(
      padding: AppSizes.screenPadding.copyWith(
        top: AppSizes.spaceLg,
        bottom: AppSizes.spaceXl + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomText(
            AppStrings.Company.inviteTitle,
            style: const TextStyle(
              fontSize: AppSizes.fontTitle,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSizes.spaceMd),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.secondColor.withValues(
                      alpha: 0.15,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(child: CustomText(steps[i])),
                ],
              ),
            ),
          const SizedBox(height: AppSizes.spaceMd),
          CompanyIdCard(company: company),
        ],
      ),
    );
  }
}
