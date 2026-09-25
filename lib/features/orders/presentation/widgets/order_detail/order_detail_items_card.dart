import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Order ticket: line items + fee breakdown (primary focus for the partner).
class OrderDetailItemsCard extends StatelessWidget {
  const OrderDetailItemsCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final serviceFee = slice.serviceFeeEgp > 0
        ? slice.serviceFeeEgp
        : OrderFeeBreakdownData.prorateServiceFee(
            masterServiceFeeEgp: row.master.serviceFeeEgp,
            masterSubtotalEgp: row.master.subtotalEgp,
            sliceOrderPriceEgp: slice.orderPriceEgp,
          );
    final delivery = slice.deliveryFeeEgp;
    final total = slice.orderPriceEgp + delivery + serviceFee;
    final items = slice.items.map(OrderItemCardData.fromSliceLine).toList();
    final storeLabel = row.master.providerOrderRefs
            .where((r) => r.providerId == slice.providerId)
            .map((r) => r.providerName?.trim())
            .whereType<String>()
            .where((n) => n.isNotEmpty)
            .firstOrNull ??
        AppStrings.Orders.detailSectionItems.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrderDetailSectionTitle(
          label: AppStrings.Orders.detailSectionItems.tr,
          icon: PhosphorIconsRegular.forkKnife,
        ),
        const SizedBox(height: AppSizes.spaceMd),
        OrderVendorItemsBlock(
          groups: [
            OrderVendorGroupData(
              providerId: slice.providerId,
              providerName: storeLabel,
              brandImageUrl: slice.providerBrandImageUrl,
              items: items,
              subtotalEgp: slice.orderPriceEgp,
            ),
          ],
          fees: OrderFeeBreakdownData(
            itemsSubtotalEgp: slice.orderPriceEgp,
            serviceFeeEgp: serviceFee,
            deliveryFeeEgp: delivery,
            totalEgp: total,
          ),
          itemsSubtotalLabel: AppStrings.Orders.detailItemsTotal.tr,
          deliveryLabel: AppStrings.Orders.detailDeliveryFee.tr,
          serviceLabel: AppStrings.Orders.detailServiceFee.tr,
          totalLabel: AppStrings.Orders.detailOrderTotal.tr,
          onServiceInfoTap: () {
            AppSnack.show(
              context,
              message: AppStrings.Orders.detailServiceFeeInfo.tr,
              state: AppSnackState.alert,
            );
          },
        ),
        if (slice.fulfillmentMode == FulfillmentMode.courier) ...[
          const SizedBox(height: AppSizes.spaceSm),
          CustomText(
            AppStrings.Orders.detailCourierFeeHint.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.55),
                ),
          ),
        ],
      ],
    );
  }
}
