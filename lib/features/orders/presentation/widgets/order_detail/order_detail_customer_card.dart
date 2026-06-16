import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailCustomerCard extends StatelessWidget {
  const OrderDetailCustomerCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final scheme = Theme.of(context).colorScheme;
    final canView = row.canViewCustomerContact;

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailCustomer.tr,
            icon: ToukhIcons.profile,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          if (!canView) ...[
            CustomText(
              AppStrings.Orders.pharmacyCustomerContactHidden.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
            ),
          ] else ...[
            CustomText(
              providerDisplayCustomerName(
                row.master,
                slice,
                genericLabel: AppStrings.Orders.detailCustomer.tr,
              ),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (slice.customerPhone != null &&
                slice.customerPhone!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSizes.spaceSm),
              Row(
                children: [
                  Icon(
                    ToukhIcons.phone,
                    size: 18,
                    color: AppColors.appColor,
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: CustomText(
                      slice.customerPhone!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.75),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
