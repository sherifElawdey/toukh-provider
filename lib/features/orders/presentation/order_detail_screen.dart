import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pickup_qr_tile.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_status_label.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
      builder: (context, state) {
        final cubit = context.read<ProviderOrdersCubit>();
        final order = cubit.orderById(orderId);

        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: CustomText(AppStrings.Orders.detailTitle.tr)),
            body: Center(
              child: Padding(
                padding: AppSizes.screenPadding,
                child: CustomText(
                  state.loading
                      ? AppStrings.Common.loading.tr
                      : AppStrings.Orders.detailNotFound.tr,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final locale = Localizations.localeOf(context).toLanguageTag();
        final fmt = DateFormat.yMMMd(locale).add_Hm();

        return Scaffold(
          appBar: AppBar(
            title: CustomText(AppStrings.Orders.detailTitle.tr),
          ),
          body: ListView(
            padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.space2xl),
            children: [
              CustomText(
                providerOrderStatusLabel(order),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.appColor,
                  fontSize: AppSizes.fontTitle,
                ),
              ),
              const SizedBox(height: 8),
              CustomText(
                '${AppStrings.Orders.detailOrderIdLabel.tr}: ${order.id}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.spaceLg),
              _sectionTitle(context, AppStrings.Orders.detailCustomer.tr),
              CustomText(order.customerName ?? '—'),
              if (order.customerPhone != null) ...[
                const SizedBox(height: 4),
                CustomText(order.customerPhone!),
              ],
              const SizedBox(height: AppSizes.spaceLg),
              _sectionTitle(context, AppStrings.Orders.detailSectionTimeline.tr),
              _timelineRow(
                context,
                AppStrings.Orders.detailCreated.tr,
                order.createdAt,
                fmt,
              ),
              _timelineRow(
                context,
                AppStrings.Orders.detailAccepted.tr,
                order.acceptedAt,
                fmt,
              ),
              _timelineRow(
                context,
                AppStrings.Orders.statusReadyForPickup.tr,
                order.readyForPickupAt,
                fmt,
              ),
              _timelineRow(
                context,
                AppStrings.Orders.statusOutForDelivery.tr,
                order.dispatchedAt,
                fmt,
              ),
              _timelineRow(
                context,
                AppStrings.Orders.detailCompleted.tr,
                order.deliveredAt,
                fmt,
              ),
              const SizedBox(height: AppSizes.spaceLg),
              _sectionTitle(context, AppStrings.Orders.detailSectionAddresses.tr),
              CustomText(
                '${AppStrings.Orders.detailPickup.tr}: ${order.storeLocation?.formattedAddress ?? order.storeLocation?.label ?? '—'}',
              ),
              const SizedBox(height: 6),
              CustomText(
                '${AppStrings.Orders.detailDropoff.tr}: ${order.deliveryAddress?.formattedAddress ?? order.deliveryAddress?.label ?? '—'}',
              ),
              if (order.note != null && order.note!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.spaceLg),
                _sectionTitle(context, AppStrings.Orders.detailSectionNotes.tr),
                CustomText(order.note!),
              ],
              if (order.masterOrderId != null &&
                  (order.canMarkReadyForPickup ||
                      order.statusWire == 'ready_for_pickup')) ...[
                const SizedBox(height: AppSizes.spaceLg),
                PickupQrTile(
                  masterOrderId: order.masterOrderId!,
                  providerId: context.read<AuthCubit>().state is Authenticated
                      ? (context.read<AuthCubit>().state as Authenticated).user.uid
                      : '',
                ),
              ],
              const SizedBox(height: AppSizes.spaceLg),
              _sectionTitle(context, AppStrings.Home.dashboardStatOrders.tr),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CustomText(
                    '${item.quantity}× ${item.name} — ${formatDashboardEgp(context, item.lineTotalEgp)}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CustomText(
                '${AppStrings.Home.dashboardStatRevenue.tr}: ${formatDashboardEgp(context, order.totalEgp)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomText(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Widget _timelineRow(
    BuildContext context,
    String label,
    DateTime? at,
    DateFormat fmt,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: CustomText(label)),
          CustomText(
            at != null ? fmt.format(at) : AppStrings.Orders.detailDatePending.tr,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
