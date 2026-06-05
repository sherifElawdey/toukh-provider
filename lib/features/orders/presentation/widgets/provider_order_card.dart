import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_order.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_status_label.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderOrderCard extends StatelessWidget {
  const ProviderOrderCard({
    super.key,
    required this.order,
    required this.tab,
    this.busy = false,
    this.onApprove,
    this.onCancel,
    this.onRequestDelivery,
    this.onReadyForPickup,
    this.onDeliver,
    this.onConfirmHandoff,
  });

  final ProviderOrder order;
  final ProviderOrdersTab tab;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onCancel;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onReadyForPickup;
  final VoidCallback? onDeliver;
  final VoidCallback? onConfirmHandoff;

  static const _compactButtonHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = tab == ProviderOrdersTab.incoming &&
        providerOrderIsOverdueIncoming(order);
    final cardColor = overdue
        ? scheme.errorContainer.withValues(alpha: 0.35)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final borderColor = overdue ? scheme.error : Colors.transparent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: overdue ? 1.5 : 0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.orderDetailPath(order.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      order.customerName ?? AppStrings.Orders.detailCustomer.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: AppSizes.fontTitle,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  _HeaderChip(order: order, tab: tab),
                ],
              ),
              if (tab == ProviderOrdersTab.incoming) ...[
                const SizedBox(height: 10),
                _IncomingMeta(order: order),
              ] else ...[
                const SizedBox(height: 6),
                CustomText(
                  formatDashboardEgp(context, order.totalEgp),
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.62),
                    fontSize: AppSizes.fontBody,
                  ),
                ),
              ],
              if (order.courierLateWarningAt != null) ...[
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
                _OutgoingMeta(order: order),
              ],
              if (tab == ProviderOrdersTab.inProgress &&
                  order.hasAssignedDriver) ...[
                const SizedBox(height: 8),
                _DriverChip(order: order),
              ],
              const SizedBox(height: 10),
              _Actions(
                order: order,
                tab: tab,
                busy: busy,
                onApprove: onApprove,
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
  const _HeaderChip({required this.order, required this.tab});

  final ProviderOrder order;
  final ProviderOrdersTab tab;

  @override
  Widget build(BuildContext context) {
    final label = tab == ProviderOrdersTab.incoming
        ? (order.isGroupOrder
            ? AppStrings.Orders.orderTypeGroup.tr
            : AppStrings.Orders.orderTypeIndividual.tr)
        : providerOrderStatusLabel(order);
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
  const _IncomingMeta({required this.order});

  final ProviderOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final placedAt = order.createdAt;
    final placedLabel = placedAt == null
        ? '—'
        : DateFormat.yMMMd(locale).add_Hm().format(placedAt);
    final elapsed = _formatElapsed(placedAt);
    final itemsLabel = _formatItemNames(order.items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetaLine(
          icon: ToukhIcons.clock,
          text:
              '${AppStrings.Orders.placedAtLabel.tr}: $placedLabel',
        ),
        if (elapsed != null) ...[
          const SizedBox(height: 4),
          _MetaLine(
            icon: ToukhIcons.orders,
            text:
                '${AppStrings.Orders.waitingElapsedLabel.tr}: $elapsed',
            emphasize: providerOrderIsOverdueIncoming(order),
          ),
        ],
        const SizedBox(height: 4),
        _MetaLine(
          icon: PhosphorIconsRegular.currencyDollar,
          text: formatDashboardEgp(context, order.orderPrice),
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

  String? _formatItemNames(List<ProviderOrderLineItem> items) {
    if (items.isEmpty) return null;
    const maxNames = 3;
    final names = items.take(maxNames).map((e) => e.name).toList();
    final remaining = items.length - names.length;
    if (remaining > 0) {
      return '${names.join(', ')} ${AppStrings.Orders.itemsMore.trParams({'count': '$remaining'})}';
    }
    return names.join(', ');
  }

  String? _formatElapsed(DateTime? from) {
    if (from == null) return null;
    final d = DateTime.now().difference(from);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.icon,
    required this.text,
    this.emphasize = false,
  });

  final IconData icon;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = emphasize ? scheme.error : scheme.onSurface.withValues(alpha: 0.72);

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
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _OutgoingMeta extends StatelessWidget {
  const _OutgoingMeta({required this.order});

  final ProviderOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = order.isStoreDelivery
        ? AppStrings.Orders.storeDeliveryLabel.tr
        : (order.driverName ?? AppStrings.Orders.courierAssignedLabel.tr);
    final elapsed = _formatElapsed(order.dispatchedAt);

    return Row(
      children: [
        Icon(
          order.isStoreDelivery ? ToukhIcons.store : ToukhIcons.delivery,
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
  const _DriverChip({required this.order});

  final ProviderOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: scheme.primaryContainer,
          backgroundImage: order.driverPhotoUrl != null
              ? NetworkImage(order.driverPhotoUrl!)
              : null,
          child: order.driverPhotoUrl == null
              ? Icon(ToukhIcons.profile, size: 18, color: scheme.primary)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            order.driverName ?? AppStrings.Orders.courierAssignedLabel.tr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.order,
    required this.tab,
    required this.busy,
    this.onApprove,
    this.onCancel,
    this.onRequestDelivery,
    this.onReadyForPickup,
    this.onDeliver,
    this.onConfirmHandoff,
  });

  final ProviderOrder order;
  final ProviderOrdersTab tab;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onCancel;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onReadyForPickup;
  final VoidCallback? onDeliver;
  final VoidCallback? onConfirmHandoff;

  @override
  Widget build(BuildContext context) {
    if (tab == ProviderOrdersTab.incoming) {
      return Row(
        children: [
          Expanded(
            child: AppOutlinedButton(
              text: AppStrings.Orders.actionCancel.tr,
              height: ProviderOrderCard._compactButtonHeight,
              onTap: busy ? null : onCancel,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppFilledButton(
              text: AppStrings.Orders.actionApprove.tr,
              height: ProviderOrderCard._compactButtonHeight,
              onTap: busy ? null : onApprove,
            ),
          ),
        ],
      );
    }

    if (tab == ProviderOrdersTab.inProgress) {
      final buttons = <Widget>[];
      if (order.isAggregated && !order.hasAssignedDriver) {
        return CustomText(
          'Driver will be assigned when all stores respond.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.65),
              ),
        );
      }
      if (order.canRequestDelivery) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionRequestDelivery.tr,
            height: ProviderOrderCard._compactButtonHeight,
            onTap: busy ? null : onRequestDelivery,
          ),
        );
      }
      if (order.canMarkReadyForPickup) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionReadyForPickup.tr,
            height: ProviderOrderCard._compactButtonHeight,
            onTap: busy ? null : onReadyForPickup,
          ),
        );
      }
      if (order.canStoreDeliver) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionDeliver.tr,
            height: ProviderOrderCard._compactButtonHeight,
            onTap: busy ? null : onDeliver,
          ),
        );
      }
      if (order.canConfirmHandoff) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionConfirmHandoff.tr,
            height: ProviderOrderCard._compactButtonHeight,
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
      onTap: () => context.push(AppRoutes.orderDetailPath(order.id)),
    );
  }
}
