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
        final row = cubit.orderById(orderId);

        if (row == null) {
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

        final slice = row.slice;
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
                providerOrderStatusLabel(row),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.appColor,
                  fontSize: AppSizes.fontTitle,
                ),
              ),
              const SizedBox(height: 8),
              CustomText(
                '${AppStrings.Orders.detailOrderIdLabel.tr}: ${row.id}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.spaceLg),
              _sectionTitle(context, AppStrings.Orders.detailCustomer.tr),
              CustomText(slice.customerName ?? '—'),
              if (slice.customerPhone != null) ...[
                const SizedBox(height: 4),
                CustomText(slice.customerPhone!),
              ],
              const SizedBox(height: AppSizes.spaceLg),
              _sectionTitle(context, AppStrings.Orders.detailSectionTimeline.tr),
              _timelineRow(
                context,
                AppStrings.Orders.detailCreated.tr,
                slice.createdAt,
                fmt,
              ),
              _timelineRow(
                context,
                AppStrings.Orders.detailAccepted.tr,
                slice.acceptedAt,
                fmt,
              ),
              _timelineRow(
                context,
                AppStrings.Orders.statusReadyForPickup.tr,
                slice.readyForPickupAt,
                fmt,
              ),
              _timelineRow(
                context,
                AppStrings.Orders.statusOutForDelivery.tr,
                slice.dispatchedAt,
                fmt,
              ),
              _timelineRow(
                context,
                AppStrings.Orders.detailCompleted.tr,
                slice.deliveredAt,
                fmt,
              ),
              const SizedBox(height: AppSizes.spaceLg),
              _sectionTitle(context, AppStrings.Orders.detailSectionAddresses.tr),
              CustomText(
                '${AppStrings.Orders.detailPickup.tr}: ${slice.storeLocation?.formattedAddress ?? slice.storeLocation?.label ?? '—'}',
              ),
              const SizedBox(height: 6),
              CustomText(
                '${AppStrings.Orders.detailDropoff.tr}: ${slice.deliveryAddress?.formattedAddress ?? slice.deliveryAddress?.label ?? row.master.deliveryAddress?.formattedAddress ?? row.master.deliveryAddress?.label ?? '—'}',
              ),
              if (slice.note != null && slice.note!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.spaceLg),
                _sectionTitle(context, AppStrings.Orders.detailSectionNotes.tr),
                CustomText(slice.note!),
              ],
              if (slice.canMarkReadyForPickup ||
                  slice.statusWire == 'ready_for_pickup') ...[
                const SizedBox(height: AppSizes.spaceLg),
                PickupQrTile(
                  masterOrderId: row.id,
                  providerId: context.read<AuthCubit>().state is Authenticated
                      ? (context.read<AuthCubit>().state as Authenticated).user.uid
                      : '',
                ),
              ],
              const SizedBox(height: AppSizes.spaceLg),
              _sectionTitle(context, AppStrings.Home.dashboardStatOrders.tr),
              ...slice.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CustomText(
                    '${item.quantity}× ${item.name} — ${formatDashboardEgp(context, item.lineTotalEgp)}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              CustomText(
                '${AppStrings.Home.dashboardStatRevenue.tr}: ${formatDashboardEgp(context, slice.totalEgp)}',
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
