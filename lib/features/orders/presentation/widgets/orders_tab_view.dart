import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/core/settings/order_acceptance_sla_cubit.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/orders_list_shimmer.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pharmacy_approve_order_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/request_delivery_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/store_driver_pick_sheet.dart';
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
        final sla = context.watch<OrderAcceptanceSlaCubit>().state;
        final auth = context.watch<AuthCubit>().state;
        final serviceTypeKey = auth is Authenticated
            ? slaKeyForProviderServiceType(auth.profile.serviceType.wireValue)
            : OrderAcceptanceSlaKeys.defaultKey;
        final rows = state.forTab(
          tab,
          acceptanceSla: sla,
          serviceTypeKey: serviceTypeKey,
        );

        if (state.loading) {
          return const OrdersListShimmer();
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
        final actionBusy = state.actionInFlightId != null;
        final providerId = auth is Authenticated ? auth.user.uid : '';

        return Stack(
          children: [
            ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSizes.screenPadding,
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                final busy = state.actionInFlightId == row.id;
                final isPharmacyRequest = row.master.isPharmacyRequest;
                final pendingPharmacy = isPharmacyRequest &&
                    row.slice.providerState ==
                        ProviderSubState.pending.wireValue;
                return ProviderOrderCard(
                  key: ValueKey(row.id),
                  row: row,
                  tab: tab,
                  busy: busy,
                  onApprove: pendingPharmacy
                      ? null
                      : () => _approveAndMaybeRequestDriver(context, row),
                  onReview: pendingPharmacy
                      ? () => showPharmacyApproveOrderSheet(context, row: row)
                      : null,
                  onCancel: () => cubit.cancel(row.id),
                  onRequestDelivery: () => _openRequestDelivery(context, row),
                  onReadyForPickup: () => cubit.markReadyForPickup(row.id),
                  onDeliver: () => _openStoreDriverPick(
                    context,
                    providerId: providerId,
                    orderId: row.id,
                  ),
                  onConfirmHandoff: () => cubit.confirmHandoff(row.id),
                  onFinish: () => _finishWithCode(context, row.id),
                );
              },
            ),
            if (actionBusy)
              Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: AppColors.scrim,
                    child: const Center(child: AppLoadingMark()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _approveAndMaybeRequestDriver(
    BuildContext context,
    ProviderMasterOrderRow row,
  ) async {
    final auth = context.read<AuthCubit>().state;
    final storeDelivers = auth is Authenticated &&
        (auth.profile.deliveryConfig?.offersDelivery ?? false);
    final openRequestSheet = !storeDelivers &&
        row.master.wouldBeFirstAccepter(row.providerId) &&
        row.slice.fulfillmentMode != FulfillmentMode.pickup &&
        !row.slice.isStoreDelivery;

    final cubit = context.read<ProviderOrdersCubit>();
    await cubit.approve(row.id);
    if (!context.mounted || !openRequestSheet) return;

    final updated = cubit.orderById(row.id) ?? row;
    await _openRequestDelivery(context, updated);
  }

  Future<void> _openStoreDriverPick(
    BuildContext context, {
    required String providerId,
    required String orderId,
  }) async {
    if (providerId.isEmpty) return;
    final driver = await showStoreDriverPickSheet(
      context,
      providerId: providerId,
    );
    if (driver == null || !context.mounted) return;
    await context.read<ProviderOrdersCubit>().assignStoreDriverAndDispatch(
          orderId: orderId,
          driverId: driver.uid,
          driverName: driver.displayName,
          driverPhotoUrl: driver.profilePhotoUrl,
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

  Future<void> _finishWithCode(BuildContext context, String orderId) async {
    final code = await showCompletionCodeSheet(context);
    if (code == null || !context.mounted) return;
    await context.read<ProviderOrdersCubit>().markDelivered(
          orderId,
          completionCode: code,
        );
  }
}
