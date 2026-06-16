import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_cancel_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailCancellationCard extends StatelessWidget {
  const OrderDetailCancellationCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final attribution = resolveCancelAttribution(row);
    if (attribution == null) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMd(locale).add_Hm();
    final cancelledAt = dateFmt.format(attribution.cancelledAt.toLocal());

    final isProvider = attribution.role == OrderCancelledByRole.provider;
    final title = isProvider
        ? AppStrings.Orders.detailCancelledByProvider.tr
        : AppStrings.Orders.detailCancelledByCustomer.tr;
    final icon = isProvider ? ToukhIcons.store : ToukhIcons.profile;

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailCancellationSection.tr,
            icon: PhosphorIconsRegular.prohibit,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(icon, size: 20, color: AppColors.error),
              ),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                    ),
                    const SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      AppStrings.Orders.detailCancelledAt.trParams({
                        'date': cancelledAt,
                      }),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                    if (attribution.cancelReason != null &&
                        attribution.cancelReason!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSizes.spaceXs),
                      CustomText(
                        AppStrings.Orders.detailCancelReason.trParams({
                          'reason': attribution.cancelReason!.trim(),
                        }),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.75),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
