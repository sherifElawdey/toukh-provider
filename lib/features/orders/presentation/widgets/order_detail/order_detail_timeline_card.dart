import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.at,
    required this.icon,
  });

  final String label;
  final DateTime? at;
  final IconData icon;
}

class OrderDetailTimelineCard extends StatelessWidget {
  const OrderDetailTimelineCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.yMMMd(locale).add_Hm();

    final steps = [
      _TimelineStep(
        label: AppStrings.Orders.detailCreated.tr,
        at: slice.createdAt,
        icon: ToukhIcons.orders,
      ),
      _TimelineStep(
        label: AppStrings.Orders.detailAccepted.tr,
        at: slice.acceptedAt,
        icon: ToukhIcons.restaurant,
      ),
      _TimelineStep(
        label: AppStrings.Orders.statusReadyForPickup.tr,
        at: slice.readyForPickupAt,
        icon: PhosphorIconsRegular.package,
      ),
      _TimelineStep(
        label: AppStrings.Orders.statusOutForDelivery.tr,
        at: slice.dispatchedAt,
        icon: ToukhIcons.delivery,
      ),
      _TimelineStep(
        label: AppStrings.Orders.detailCompleted.tr,
        at: slice.deliveredAt,
        icon: ToukhIcons.success,
      ),
    ];

    if (slice.cancelledAt != null) {
      steps.add(
        _TimelineStep(
          label: AppStrings.Orders.detailCancelled.tr,
          at: slice.cancelledAt,
          icon: PhosphorIconsRegular.prohibit,
        ),
      );
    }

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailSectionTimeline.tr,
            icon: ToukhIcons.history,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          ...List.generate(steps.length, (i) {
            final step = steps[i];
            final done = step.at != null;
            final isLast = i == steps.length - 1;
            return _TimelineStepRow(
              label: step.label,
              timeLabel: done
                  ? fmt.format(step.at!)
                  : AppStrings.Orders.detailDatePending.tr,
              icon: step.icon,
              done: done,
              showConnector: !isLast,
              connectorDone: done && steps[i + 1].at != null,
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineStepRow extends StatelessWidget {
  const _TimelineStepRow({
    required this.label,
    required this.timeLabel,
    required this.icon,
    required this.done,
    required this.showConnector,
    required this.connectorDone,
  });

  final String label;
  final String timeLabel;
  final IconData icon;
  final bool done;
  final bool showConnector;
  final bool connectorDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dotColor = done ? AppColors.success : scheme.onSurface.withValues(alpha: 0.25);
    final lineColor = connectorDone
        ? AppColors.success.withValues(alpha: 0.5)
        : AppColors.borderSubtle;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.success.withValues(alpha: 0.15)
                        : scheme.surface,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: Icon(
                    done ? ToukhIcons.success : icon,
                    size: 14,
                    color: dotColor,
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? AppSizes.spaceMd : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: done
                              ? scheme.onSurface
                              : scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
