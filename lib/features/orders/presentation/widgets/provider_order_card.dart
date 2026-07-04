import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/incoming_order_wait_counter.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_status_label.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderOrderCard extends StatelessWidget {
  const ProviderOrderCard({
    super.key,
    required this.row,
    required this.tab,
    this.busy = false,
    this.onApprove,
    this.onReview,
    this.onCancel,
    this.onRequestDelivery,
    this.onReadyForPickup,
    this.onDeliver,
    this.onConfirmHandoff,
  });

  final ProviderMasterOrderRow row;
  final ProviderOrdersTab tab;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReview;
  final VoidCallback? onCancel;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onReadyForPickup;
  final VoidCallback? onDeliver;
  final VoidCallback? onConfirmHandoff;

  ProviderOrderSlice get _slice => row.slice;

  static const _compactButtonHeight = 45.0;

  @override
  Widget build(BuildContext context) {
    if (tab == ProviderOrdersTab.incoming) {
      return IncomingOrderTimedBuilder(
        key: ValueKey(row.id),
        row: row,
        builder: (context, elapsed, urgency, hasPlacementTime) => _buildCard(
          context,
          urgency: urgency,
          elapsed: elapsed,
          hasPlacementTime: hasPlacementTime,
        ),
      );
    }
    return _buildCard(context);
  }

  Widget _buildCard(
    BuildContext context, {
    IncomingOrderUrgency urgency = IncomingOrderUrgency.normal,
    Duration elapsed = Duration.zero,
    bool hasPlacementTime = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final decoration = tab == ProviderOrdersTab.incoming
        ? incomingOrderUrgencyDecoration(urgency, scheme)
        : incomingOrderUrgencyDecoration(IncomingOrderUrgency.normal, scheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: decoration.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: decoration.border,
          width: decoration.borderWidth,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.orderDetailPath(row.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      providerDisplayCustomerName(
                        row.master,
                        _slice,
                        genericLabel:
                            AppStrings.Orders.pharmacyRequestCustomerLabel.tr,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: AppSizes.fontTitle,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  _HeaderChip(row: row, tab: tab),
                ],
              ),
              if (tab == ProviderOrdersTab.incoming) ...[
                const SizedBox(height: 8),
                _IncomingMeta(
                  row: row,
                  elapsed: elapsed,
                  urgency: urgency,
                  hasPlacementTime: hasPlacementTime,
                ),
              ] else ...[
                const SizedBox(height: 6),
                CustomText(
                  formatDashboardEgp(context, _slice.totalEgp),
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.62),
                    fontSize: AppSizes.fontBody,
                  ),
                ),
              ],
              if (_slice.courierLateWarningAt != null) ...[
                const SizedBox(height: 8),
                CustomText(
                  AppStrings.Orders.courierLateWarning.tr,
                  style: TextStyle(
                    color: scheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (tab == ProviderOrdersTab.outgoing) ...[
                const SizedBox(height: 8),
                _OutgoingMeta(row: row),
              ],
              if (tab == ProviderOrdersTab.inProgress && _slice.hasAssignedDriver) ...[
                const SizedBox(height: 8),
                _DriverChip(row: row),
              ],
              const SizedBox(height: 10),
              _Actions(
                row: row,
                tab: tab,
                busy: busy,
                onApprove: onApprove,
                onReview: onReview,
                onCancel: onCancel,
                onRequestDelivery: onRequestDelivery,
                onReadyForPickup: onReadyForPickup,
                onDeliver: onDeliver,
                onConfirmHandoff: onConfirmHandoff,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.row, required this.tab});

  final ProviderMasterOrderRow row;
  final ProviderOrdersTab tab;

  @override
  Widget build(BuildContext context) {
    final label = tab == ProviderOrdersTab.incoming
        ? (row.slice.isGroupOrder
            ? AppStrings.Orders.orderTypeGroup.tr
            : AppStrings.Orders.orderTypeIndividual.tr)
        : providerOrderStatusLabel(row);
    final color = tab == ProviderOrdersTab.incoming
        ? AppColors.secondColor
        : AppColors.appColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomText(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _IncomingMeta extends StatelessWidget {
  const _IncomingMeta({
    required this.row,
    required this.elapsed,
    required this.urgency,
    required this.hasPlacementTime,
  });

  final ProviderMasterOrderRow row;
  final Duration elapsed;
  final IncomingOrderUrgency urgency;
  final bool hasPlacementTime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final placedAt = row.slice.createdAt;
    final placedLabel = placedAt == null
        ? '—'
        : formatDateLabel(placedAt,locale: locale);
    final itemsLabel = _formatItemNames(row.slice.items);
    final metaColor = scheme.onSurface.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              ToukhIcons.clock,
              size: 16,
              color: metaColor.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomText(
                '${AppStrings.Orders.placedAtLabel.tr}: $placedLabel',
                style: TextStyle(
                  color: metaColor,
                  fontSize: AppSizes.fontBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IncomingOrderWaitCounter(
              elapsed: elapsed,
              urgency: urgency,
              hasPlacementTime: hasPlacementTime,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _MetaLine(
          icon: PhosphorIconsRegular.currencyDollar,
          text: formatDashboardEgp(context, row.slice.orderPriceEgp),
        ),
        if (itemsLabel != null) ...[
          const SizedBox(height: 4),
          CustomText(
            itemsLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.72),
              fontSize: AppSizes.fontBody,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  String? _formatItemNames(List<ProviderOrderSliceLineItem> items) {
    if (items.isEmpty) return null;
    const maxNames = 3;
    final names = items.take(maxNames).map((e) => e.name).toList();
    final remaining = items.length - names.length;
    final explorePrefix = row.slice.fulfillmentMode.wireValue == 'pickup'
        ? '${AppStrings.Orders.exploreItemsLabel.tr} · '
        : '';
    if (remaining > 0) {
      return '$explorePrefix${names.join(', ')} ${AppStrings.Orders.itemsMore.trParams({'count': '$remaining'})}';
    }
    return '$explorePrefix${names.join(', ')}';
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = scheme.onSurface.withValues(alpha: 0.72);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            text,
            style: TextStyle(
              color: color,
              fontSize: AppSizes.fontBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutgoingMeta extends StatelessWidget {
  const _OutgoingMeta({required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slice = row.slice;
    final label = slice.isStoreDelivery
        ? AppStrings.Orders.storeDeliveryLabel.tr
        : (slice.driverName ?? AppStrings.Orders.courierAssignedLabel.tr);
    final elapsed = _formatElapsed(slice.dispatchedAt);

    return Row(
      children: [
        Icon(
          slice.isStoreDelivery ? ToukhIcons.store : ToukhIcons.delivery,
          size: 18,
          color: scheme.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ),
        if (elapsed != null)
          CustomText(
            '${AppStrings.Orders.elapsedSinceDispatch.tr} $elapsed',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }

  String? _formatElapsed(DateTime? from) {
    if (from == null) return null;
    final d = DateTime.now().difference(from);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}

class _DriverChip extends StatelessWidget {
  const _DriverChip({required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slice = row.slice;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: slice.driverPhotoUrl != null
              ? NetworkImage(slice.driverPhotoUrl!)
              : null,
          child: slice.driverPhotoUrl == null
              ? Icon(ToukhIcons.profile, size: 18, color: scheme.primary)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            slice.driverName ?? AppStrings.Orders.courierAssignedLabel.tr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.row,
    required this.tab,
    required this.busy,
    this.onApprove,
    this.onReview,
    this.onCancel,
    this.onRequestDelivery,
    this.onReadyForPickup,
    this.onDeliver,
    this.onConfirmHandoff,
  });

  final ProviderMasterOrderRow row;
  final ProviderOrdersTab tab;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReview;
  final VoidCallback? onCancel;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onReadyForPickup;
  final VoidCallback? onDeliver;
  final VoidCallback? onConfirmHandoff;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;

    if (tab == ProviderOrdersTab.incoming) {
      return Row(
        children: [
          Expanded(
            child: AppOutlinedButton(
              text: AppStrings.Orders.actionCancel.tr,
              size: AppButtonSize.small,
              height: ProviderOrderCard._compactButtonHeight,
              onTap: busy ? null : onCancel,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppFilledButton(
              text: onReview != null
                  ? AppStrings.Orders.pharmacyReviewOrder.tr
                  : AppStrings.Orders.actionApprove.tr,
              height: ProviderOrderCard._compactButtonHeight,
              size: AppButtonSize.small,
              onTap: busy ? null : (onReview ?? onApprove),
            ),
          ),
        ],
      );
    }

    if (tab == ProviderOrdersTab.inProgress) {
      final buttons = <Widget>[];
      if (slice.isAggregated && !slice.hasAssignedDriver) {
        return CustomText(
          'Driver will be assigned when all stores respond.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.65),
              ),
        );
      }
      if (slice.canRequestDelivery) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionRequestDelivery.tr,
            height: ProviderOrderCard._compactButtonHeight,
            size: AppButtonSize.small,
            onTap: busy ? null : onRequestDelivery,
          ),
        );
      }
      if (slice.canMarkReadyForPickup) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionReadyForPickup.tr,
            height: ProviderOrderCard._compactButtonHeight,
            size: AppButtonSize.small,
            onTap: busy ? null : onReadyForPickup,
          ),
        );
      }
      if (slice.canStoreDeliver) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionDeliver.tr,
            height: ProviderOrderCard._compactButtonHeight,
            size: AppButtonSize.small,
            onTap: busy ? null : onDeliver,
          ),
        );
      }
      if (slice.canConfirmHandoff) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionConfirmHandoff.tr,
            height: ProviderOrderCard._compactButtonHeight,
            size: AppButtonSize.small,
            onTap: busy ? null : onConfirmHandoff,
          ),
        );
      }
      if (buttons.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            buttons[i],
          ],
        ],
      );
    }

    return AppTextButton(
      text: AppStrings.Orders.seeDetails.tr,
      size: AppButtonSize.small,
      onTap: () => context.push(AppRoutes.orderDetailPath(row.id)),
    );
  }
}
