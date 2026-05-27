import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.appColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      providerOrderStatusLabel(order),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.appColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              CustomText(
                '#$shortId · ${formatDashboardEgp(context, order.totalEgp)}',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.62),
                  fontSize: AppSizes.fontBody,
                ),
              ),
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
              const SizedBox(height: 12),
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
          order.isStoreDelivery
              ? Icons.storefront_outlined
              : Icons.delivery_dining_outlined,
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
              ? Icon(Icons.person, size: 18, color: scheme.primary)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomText(
            order.driverName ?? AppStrings.Orders.courierAssignedLabel.tr,
            style: TextStyle(fontWeight: FontWeight.w600),
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
              onTap: busy ? null : onCancel,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppFilledButton(
              text: AppStrings.Orders.actionApprove.tr,
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
            onTap: busy ? null : onRequestDelivery,
          ),
        );
      }
      if (order.canMarkReadyForPickup) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionReadyForPickup.tr,
            onTap: busy ? null : onReadyForPickup,
          ),
        );
      }
      if (order.canStoreDeliver) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionDeliver.tr,
            onTap: busy ? null : onDeliver,
          ),
        );
      }
      if (order.canConfirmHandoff) {
        buttons.add(
          AppFilledButton(
            text: AppStrings.Orders.actionConfirmHandoff.tr,
            onTap: busy ? null : onConfirmHandoff,
          ),
        );
      }
      if (buttons.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
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
