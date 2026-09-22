import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/settings/order_acceptance_sla_cubit.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/delivery_qr_scan_screen.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/orders_list_shimmer.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pharmacy_approve_order_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pickup_qr_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/request_delivery_location.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/request_delivery_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/store_driver_pick_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
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
          return ToukhRefresh(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                HomeDashboardEmptyPlaceholder(
                  message: emptyMessageKey,
                ),
              ],
            ),
          );
        }

        final cubit = context.read<ProviderOrdersCubit>();
        final actionBusy = state.actionInFlightId != null;
        final providerId = auth is Authenticated ? auth.user.uid : '';

        return Stack(
          children: [
            ToukhRefresh(
              onRefresh: () => _refresh(context),
              child: ListView.builder(
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
                    onShowPickupQr: () => showPickupQrSheet(
                      context,
                      masterOrderId: row.id,
                      providerId: providerId,
                      driverId: row.slice.driverId ??
                          row.master.driverAssignment?.driverId,
                    ),
                    onFinish: () => _finishWithCode(context, row.id),
                  );
                },
              ),
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

  Future<void> _refresh(BuildContext context) async {
    context.read<ProviderOrdersCubit>().refresh();
    await Future<void>.delayed(const Duration(milliseconds: 450));
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
    final auth = context.read<AuthCubit>().state;
    final profile = auth is Authenticated ? auth.profile : null;
    final center = resolveDriverRequestPickup(
      profile: profile,
      sliceStoreLocation: row.slice.storeLocation,
    );
    if (center == null) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Orders.requestDeliveryMissingLocation.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.location,
      );
      return;
    }
    await cubit.requestDelivery(orderId: row.id, searchCenter: center);
    if (!context.mounted) return;
    final updated = cubit.orderById(row.id);
    if (updated?.slice.hasAssignedDriver ?? false) {
      await showDriverAssignedSheet(context, row: updated!);
    }
  }

  Future<void> _finishWithCode(BuildContext context, String orderId) async {
    final method = await showHandoffMethodSheet(
      context,
      title: AppStrings.Orders.deliverMethodTitle.tr,
      subtitle: AppStrings.Orders.deliverMethodSubtitle.tr,
      qrLabel: AppStrings.Orders.deliverWithQr.tr,
      otpLabel: AppStrings.Orders.deliverWithOtp.tr,
    );
    if (method == null || !context.mounted) return;

    if (method == HandoffMethod.qrCode) {
      final payload = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const DeliveryQrScanScreen()),
      );
      if (payload == null || !context.mounted) return;
      await context.read<ProviderOrdersCubit>().markDeliveredViaQr(payload);
      return;
    }

    final code = await showCompletionCodeSheet(context);
    if (code == null || !context.mounted) return;
    await context.read<ProviderOrdersCubit>().markDelivered(
          orderId,
          completionCode: code,
        );
  }
}
