import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        final rows = state.forTab(tab);
        if (state.loading && rows.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (rows.isEmpty) {
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
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final busy = state.actionInFlightId == row.id;
            return ProviderOrderCard(
              key: ValueKey(row.id),
              row: row,
              tab: tab,
              busy: busy,
              onApprove: () => cubit.approve(row.id),
              onCancel: () => cubit.cancel(row.id),
              onRequestDelivery: () => _openRequestDelivery(context, row),
              onReadyForPickup: () => cubit.markReadyForPickup(row.id),
              onDeliver: () => cubit.markStoreOutForDelivery(row.id),
              onConfirmHandoff: () => cubit.confirmHandoff(row.id),
            );
          },
        );
      },
    );
  }

  Future<void> _openRequestDelivery(
    BuildContext context,
    ProviderMasterOrderRow row,
  ) async {
    final cubit = context.read<ProviderOrdersCubit>();
    final center = await showRequestDeliverySheet(
      context,
      initialLocation: row.slice.storeLocation,
    );
    if (center == null || !context.mounted) return;
    await cubit.requestDelivery(orderId: row.id, searchCenter: center);
    if (!context.mounted) return;
    final updated = cubit.orderById(row.id);
    if (updated?.slice.hasAssignedDriver ?? false) {
      await showDriverAssignedSheet(context, row: updated!);
    }
  }
}
