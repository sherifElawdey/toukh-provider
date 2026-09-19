import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_cancellation_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_client_details_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_items_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_notes_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_pharmacy_request_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_status_header.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_timeline_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pharmacy_approve_order_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_actions_bar.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_cancel_ui.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pickup_qr_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pickup_qr_tile.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/request_delivery_location.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/request_delivery_sheet.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/store_driver_pick_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:toukh_ui/toukh_ui.dart';

void _leaveOrderDetail(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.orders);
  }
}

ProviderOrdersTab _tabForSlice(ProviderOrderSlice slice) {
  if (slice.isIncoming) return ProviderOrdersTab.incoming;
  if (slice.isOutgoing) return ProviderOrdersTab.outgoing;
  if (slice.isDelivered || slice.isTerminal) return ProviderOrdersTab.delivered;
  return ProviderOrdersTab.inProgress;
}

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  ProviderMasterOrderRow? _fetchedRow;
  bool _fetching = false;
  bool _fetchAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryFetchFallback());
  }

  Future<void> _tryFetchFallback() async {
    if (_fetchAttempted || !mounted) return;
    final cubit = context.read<ProviderOrdersCubit>();
    if (cubit.orderById(widget.orderId) != null) return;

    final auth = context.read<AuthCubit>().state;
    if (auth is! Authenticated) return;

    setState(() {
      _fetching = true;
      _fetchAttempted = true;
    });

    try {
      final order = await getIt<ProviderOrdersRepository>().getOrderById(
        providerId: auth.user.uid,
        orderId: widget.orderId,
      );
      if (!mounted || order == null) return;
      setState(() {
        _fetchedRow = ProviderMasterOrderRow.fromMaster(order, auth.user.uid);
      });
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
      builder: (context, state) {
        final cubit = context.read<ProviderOrdersCubit>();
        final row = cubit.orderById(widget.orderId) ?? _fetchedRow;

        if (row == null) {
          final loading = state.loading || _fetching;
          return Scaffold(
            appBar: AppBar(
              title: CustomText(AppStrings.Orders.detailTitle.tr),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _leaveOrderDetail(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: AppSizes.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const AppLoadingMark()
                    else
                      Icon(
                        PhosphorIconsRegular.receipt,
                        size: 48,
                        color: AppColors.onSurface.withValues(alpha: 0.35),
                      ),
                    const SizedBox(height: AppSizes.spaceMd),
                    CustomText(
                      loading
                          ? AppStrings.Common.loading.tr
                          : AppStrings.Orders.detailNotFound.tr,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final busy = state.actionInFlightId == row.id;
        return _OrderDetailBody(row: row, busy: busy);
      },
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.row, required this.busy});

  final ProviderMasterOrderRow row;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final auth = context.read<AuthCubit>().state;
    final providerId =
        auth is Authenticated ? auth.user.uid : slice.providerId;
    final tab = _tabForSlice(slice);
    final isPharmacyRequest = row.master.isPharmacyRequest;
    final pendingPharmacy = isPharmacyRequest &&
        slice.providerState == ProviderSubState.pending.wireValue;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Orders.detailTitle.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _leaveOrderDetail(context),
        ),
      ),
      body: ListView(
        padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.space2xl),
        children: [
          OrderDetailStatusHeader(row: row),
          if (resolveCancelAttribution(row) != null) ...[
            const SizedBox(height: AppSizes.spaceMd),
            OrderDetailCancellationCard(row: row),
          ],
          const SizedBox(height: AppSizes.spaceLg),
          if (row.hasAssignedDriverEffective) ...[
            _DetailDriverCard(row: row),
            const SizedBox(height: AppSizes.spaceMd),
          ],
          ProviderOrderActionsBar(
            row: row,
            tab: tab,
            busy: busy,
            compact: false,
            onApprove: pendingPharmacy
                ? null
                : () => _approveAndMaybeRequestDriver(context, row),
            onReview: pendingPharmacy
                ? () => showPharmacyApproveOrderSheet(context, row: row)
                : null,
            onCancel: () => context.read<ProviderOrdersCubit>().cancel(row.id),
            onRequestDelivery: () => _openRequestDelivery(context, row),
            onReadyForPickup: () =>
                context.read<ProviderOrdersCubit>().markReadyForPickup(row.id),
            onDeliver: () => _openStoreDriverPick(
              context,
              providerId: providerId,
              orderId: row.id,
            ),
            onShowPickupQr: () => showPickupQrSheet(
              context,
              masterOrderId: row.id,
              providerId: providerId,
              driverId:
                  slice.driverId ?? row.master.driverAssignment?.driverId,
            ),
            onFinish: () => _finishWithCode(context, row.id),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          OrderDetailClientDetailsCard(row: row),
          const SizedBox(height: AppSizes.spaceMd),
          OrderDetailTimelineCard(row: row),
          if (row.master.isPharmacyRequest) ...[
            const SizedBox(height: AppSizes.spaceMd),
            OrderDetailPharmacyRequestCard(row: row),
          ],
          if (slice.note != null && slice.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.spaceMd),
            OrderDetailNotesCard(note: slice.note!.trim()),
          ],
          if (row.canShowPickupQr) ...[
            const SizedBox(height: AppSizes.spaceMd),
            PickupQrTile(
              masterOrderId: row.id,
              providerId: providerId,
              driverId: slice.driverId ?? row.master.driverAssignment?.driverId,
            ),
          ],
          const SizedBox(height: AppSizes.spaceMd),
          OrderDetailItemsCard(row: row),
        ],
      ),
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
    if (updated?.hasAssignedDriverEffective ?? false) {
      await showDriverAssignedSheet(context, row: updated!);
    }
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

  Future<void> _finishWithCode(BuildContext context, String orderId) async {
    final code = await showCompletionCodeSheet(context);
    if (code == null || !context.mounted) return;
    await context.read<ProviderOrdersCubit>().markDelivered(
          orderId,
          completionCode: code,
        );
  }
}

class _DetailDriverCard extends StatelessWidget {
  const _DetailDriverCard({required this.row});

  final ProviderMasterOrderRow row;

  Future<void> _call(String raw) async {
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final assignment = row.master.driverAssignment;
    final name = slice.driverName?.trim().isNotEmpty == true
        ? slice.driverName!
        : (assignment?.driverName?.trim().isNotEmpty == true
            ? assignment!.driverName!
            : AppStrings.Orders.courierAssignedLabel.tr);
    final photo = slice.driverPhotoUrl ?? assignment?.driverPhotoUrl;
    final phone =
        slice.driverPhone?.trim() ?? assignment?.driverPhone?.trim();
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Icon(ToukhIcons.profile, color: scheme.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.Orders.detailDriverAssigned.tr,
                  style: t.labelMedium?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                CustomText(
                  name,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    phone,
                    style: t.bodySmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            IconButton(
              onPressed: () => _call(phone),
              icon: Icon(ToukhIcons.phone, color: scheme.primary),
            ),
        ],
      ),
    );
  }
}
