import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailTimelineCard extends StatelessWidget {
  const OrderDetailTimelineCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final searchStarted = row.effectiveDeliveryRequestedAt;
    final driverAssignedAt = row.master.driverAssignment?.assignedAt;

    final candidates = <({
      String id,
      String label,
      IconData icon,
      DateTime? at,
    })>[
      (
        id: 'created',
        label: AppStrings.Orders.detailCreated.tr,
        icon: PhosphorIconsRegular.shoppingBag,
        at: slice.createdAt,
      ),
      (
        id: 'accepted',
        label: AppStrings.Orders.detailAccepted.tr,
        icon: PhosphorIconsRegular.forkKnife,
        at: slice.acceptedAt,
      ),
      if (!slice.isStoreDelivery && searchStarted != null)
        (
          id: 'search',
          label: AppStrings.Orders.detailDriverSearchStarted.tr,
          icon: PhosphorIconsRegular.magnifyingGlass,
          at: searchStarted,
        ),
      if (!slice.isStoreDelivery &&
          (driverAssignedAt != null || row.hasAssignedDriverEffective))
        (
          id: 'driver',
          label: AppStrings.Orders.detailDriverAssigned.tr,
          icon: PhosphorIconsRegular.motorcycle,
          at: driverAssignedAt ?? slice.acceptedAt,
        ),
      if (!slice.isStoreDelivery)
        (
          id: 'ready',
          label: AppStrings.Orders.statusReadyForPickup.tr,
          icon: PhosphorIconsRegular.package,
          at: slice.readyForPickupAt,
        ),
      (
        id: 'out',
        label: AppStrings.Orders.statusOutForDelivery.tr,
        icon: PhosphorIconsRegular.navigationArrow,
        at: slice.dispatchedAt,
      ),
      (
        id: 'done',
        label: AppStrings.Orders.detailCompleted.tr,
        icon: PhosphorIconsRegular.flagCheckered,
        at: slice.deliveredAt,
      ),
      if (slice.cancelledAt != null)
        (
          id: 'cancelled',
          label: AppStrings.Orders.detailCancelled.tr,
          icon: PhosphorIconsRegular.prohibit,
          at: slice.cancelledAt,
        ),
    ];

    var activeIndex = -1;
    for (var i = 0; i < candidates.length; i++) {
      if (candidates[i].at != null) activeIndex = i;
    }
    if (slice.cancelledAt == null &&
        slice.deliveredAt == null &&
        activeIndex < candidates.length - 1) {
      activeIndex = (activeIndex + 1).clamp(0, candidates.length - 1);
    }

    final steps = <OrderTrackStepData>[
      for (var i = 0; i < candidates.length; i++)
        OrderTrackStepData(
          id: candidates[i].id,
          label: candidates[i].label,
          icon: candidates[i].icon,
          at: candidates[i].at,
          isDone: candidates[i].at != null &&
              (i < activeIndex ||
                  slice.deliveredAt != null ||
                  slice.cancelledAt != null),
          isActive: i == activeIndex &&
              slice.deliveredAt == null &&
              slice.cancelledAt == null,
        ),
    ];

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailSectionTimeline.tr,
            icon: PhosphorIconsRegular.flagBanner,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          OrderStepTrack(steps: steps),
        ],
      ),
    );
  }
}
