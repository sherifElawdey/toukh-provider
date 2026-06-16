import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailItemsCard extends StatelessWidget {
  const OrderDetailItemsCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailSectionItems.tr,
            icon: ToukhIcons.orders,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          if (slice.items.isEmpty)
            CustomText(
              '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.5),
              ),
            )
          else
            ...slice.items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: AppColors.borderSubtle.withValues(alpha: 0.8),
                    ),
                  if (i > 0) const SizedBox(height: AppSizes.spaceSm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.appColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomText(
                          '${item.quantity}×',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: AppSizes.fontLabel,
                            color: AppColors.appColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spaceSm),
                      Expanded(
                        child: CustomText(
                          item.name,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      CustomText(
                        formatDashboardEgp(context, item.lineTotalEgp),
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                  if (i < slice.items.length - 1)
                    const SizedBox(height: AppSizes.spaceSm),
                ],
              );
            }),
          const SizedBox(height: AppSizes.spaceMd),
          Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSizes.spaceSm),
          _SummaryRow(
            label: AppStrings.Orders.detailSubtotal.tr,
            value: formatDashboardEgp(context, slice.orderPriceEgp),
          ),
          if (slice.deliveryFeeEgp > 0) ...[
            const SizedBox(height: AppSizes.spaceXs),
            _SummaryRow(
              label: AppStrings.Orders.detailDeliveryFee.tr,
              value: formatDashboardEgp(context, slice.deliveryFeeEgp),
            ),
          ],
          const SizedBox(height: AppSizes.spaceSm),
          _SummaryRow(
            label: AppStrings.Orders.detailOrderTotal.tr,
            value: formatDashboardEgp(context, slice.totalEgp),
            emphasize: true,
            valueColor: AppColors.appColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: CustomText(
            label,
            style: (emphasize ? t.titleSmall : t.bodyMedium)?.copyWith(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
              color: AppColors.onSurface.withValues(
                alpha: emphasize ? 1 : 0.65,
              ),
            ),
          ),
        ),
        CustomText(
          value,
          style: (emphasize ? t.titleMedium : t.bodyMedium)?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
