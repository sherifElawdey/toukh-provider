import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/domain/entities/provider_order.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/request_delivery_sheet.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrdersTabView extends StatelessWidget {
  const OrdersTabView({
    super.key,
    required this.tab,
    required this.emptyMessageKey,
  });

  final ProviderOrdersTab tab;
  final String emptyMessageKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
      builder: (context, state) {
        final orders = state.forTab(tab);
        if (state.loading && orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orders.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              HomeDashboardEmptyPlaceholder(
                message: emptyMessageKey,
              ),
            ],
          );
        }

        final cubit = context.read<ProviderOrdersCubit>();
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSizes.screenPadding,
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final busy = state.actionInFlightId == order.id;
            return ProviderOrderCard(
              order: order,
              tab: tab,
              busy: busy,
              onApprove: () => cubit.approve(order.id),
              onCancel: () => cubit.cancel(order.id),
              onRequestDelivery: () => _openRequestDelivery(context, order),
              onReadyForPickup: () => cubit.markReadyForPickup(order.id),
              onDeliver: () => cubit.markStoreOutForDelivery(order.id),
              onConfirmHandoff: () => cubit.confirmHandoff(order.id),
            );
          },
        );
      },
    );
  }

  Future<void> _openRequestDelivery(BuildContext context, ProviderOrder order) async {
    final cubit = context.read<ProviderOrdersCubit>();
    final center = await showRequestDeliverySheet(
      context,
      initialLocation: order.storeLocation,
    );
    if (center == null || !context.mounted) return;
    await cubit.requestDelivery(orderId: order.id, searchCenter: center);
    if (!context.mounted) return;
    final updated = cubit.orderById(order.id);
    if (updated?.hasAssignedDriver ?? false) {
      await showDriverAssignedSheet(context, order: updated!);
    }
  }
}
