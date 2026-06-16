import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/network_image_zoom_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailPharmacyRequestCard extends StatelessWidget {
  const OrderDetailPharmacyRequestCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final master = row.master;
    if (!master.isPharmacyRequest) return const SizedBox.shrink();

    final req = master.pharmacyRequest;
    final slice = row.slice;
    final quote = slice.pharmacyQuote;
    final t = Theme.of(context).textTheme;

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.pharmacyApproveTitle.tr,
            icon: PhosphorIconsRegular.pill,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          if (req?.prescriptionImageUrl != null &&
              req!.prescriptionImageUrl!.isNotEmpty) ...[
            TappableNetworkImage(
                imageUrl: req.prescriptionImageUrl!,
                height: 140,
                width: double.infinity,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            const SizedBox(height: AppSizes.spaceMd),
          ],
          if (req?.customerNote != null && req!.customerNote!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
              child: CustomText(
                req.customerNote!.trim(),
                style: t.bodyMedium,
              ),
            ),
          if (req != null && req.items.isNotEmpty) ...[
            for (final item in req.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceXs),
                child: CustomText(
                  '${item.quantityText} · ${item.nameDescription}',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: AppSizes.spaceSm),
          ],
          if (quote != null) ...[
            Divider(color: AppColors.borderSubtle.withValues(alpha: 0.8)),
            const SizedBox(height: AppSizes.spaceSm),
            if (quote.pharmacistNote != null &&
                quote.pharmacistNote!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.Orders.pharmacyPharmacistNote.tr,
                      style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    CustomText(quote.pharmacistNote!.trim()),
                  ],
                ),
              ),
            CustomText(
              'EGP ${quote.quotedTotalEgp.toStringAsFixed(0)}',
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.appColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
