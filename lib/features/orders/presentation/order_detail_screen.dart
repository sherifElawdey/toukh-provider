import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_addresses_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_cancellation_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_customer_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_items_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_notes_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_pharmacy_request_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_status_header.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_timeline_card.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_cancel_ui.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pickup_qr_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

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
            appBar: AppBar(title: CustomText(AppStrings.Orders.detailTitle.tr)),
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

        return _OrderDetailBody(row: row);
      },
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final auth = context.read<AuthCubit>().state;
    final providerId =
        auth is Authenticated ? auth.user.uid : slice.providerId;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Orders.detailTitle.tr),
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
          OrderDetailCustomerCard(row: row),
          const SizedBox(height: AppSizes.spaceMd),
          OrderDetailTimelineCard(row: row),
          const SizedBox(height: AppSizes.spaceMd),
          OrderDetailAddressesCard(row: row),
          if (row.master.isPharmacyRequest) ...[
            const SizedBox(height: AppSizes.spaceMd),
            OrderDetailPharmacyRequestCard(row: row),
          ],
          if (slice.note != null && slice.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.spaceMd),
            OrderDetailNotesCard(note: slice.note!.trim()),
          ],
          if (slice.canMarkReadyForPickup ||
              slice.statusWire == 'ready_for_pickup') ...[
            const SizedBox(height: AppSizes.spaceMd),
            PickupQrTile(
              masterOrderId: row.id,
              providerId: providerId,
            ),
          ],
          const SizedBox(height: AppSizes.spaceMd),
          OrderDetailItemsCard(row: row),
        ],
      ),
    );
  }
}
