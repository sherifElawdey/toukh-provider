import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailNotesCard extends StatelessWidget {
  const OrderDetailNotesCard({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailSectionNotes.tr,
            icon: PhosphorIconsRegular.note,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.thirdColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: CustomText(
              note,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
