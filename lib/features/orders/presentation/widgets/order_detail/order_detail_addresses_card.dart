import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailAddressesCard extends StatelessWidget {
  const OrderDetailAddressesCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final pickupTitle =
        slice.storeLocation?.label ?? AppStrings.Orders.detailPickup.tr;
    final pickupSubtitle = slice.storeLocation?.formattedAddress ??
        slice.storeLocation?.label ??
        '—';
    final dropTitle =
        slice.deliveryAddress?.label ?? AppStrings.Orders.detailDropoff.tr;
    final dropSubtitle = slice.deliveryAddress?.formattedAddress ??
        slice.deliveryAddress?.label ??
        row.master.deliveryAddress.formattedAddress ??
        row.master.deliveryAddress.label ??
        '—';

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailSectionAddresses.tr,
            icon: ToukhIcons.location,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          _AddressInfoRow(
            icon: ToukhIcons.store,
            title: pickupTitle,
            subtitle: pickupSubtitle,
          ),
          const SizedBox(height: AppSizes.spaceSm),
          _AddressInfoRow(
            icon: ToukhIcons.location,
            title: dropTitle,
            subtitle: dropSubtitle,
          ),
        ],
      ),
    );
  }
}

class _AddressInfoRow extends StatelessWidget {
  const _AddressInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.thirdColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.appColor, size: 22),
          const SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  CustomText(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.65),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
