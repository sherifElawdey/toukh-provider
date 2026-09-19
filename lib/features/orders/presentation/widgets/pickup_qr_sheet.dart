import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/pickup_qr_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Bottom sheet so the provider can show the pickup QR for the courier to scan.
///
/// When the driver successfully scans, the sheet closes and a success dialog
/// is shown on the caller [context].
Future<void> showPickupQrSheet(
  BuildContext context, {
  required String masterOrderId,
  required String providerId,
  String? driverId,
}) async {
  final handedOff = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => BlocProvider.value(
      value: getIt<ProviderOrdersCubit>(),
      child: _PickupQrSheetBody(
        masterOrderId: masterOrderId,
        providerId: providerId,
        driverId: driverId,
      ),
    ),
  );

  if (handedOff == true && context.mounted) {
    await showCourierHandoffSuccessDialog(context);
  }
}

/// Success dialog after courier QR pickup verification.
Future<void> showCourierHandoffSuccessDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(
          PhosphorIconsRegular.checkCircle,
          color: AppColors.success,
          size: AppSizes.iconLg,
        ),
        title: CustomText(
          AppStrings.Orders.handoffSuccessTitle.tr,
          textAlign: TextAlign.center,
        ),
        content: CustomText(
          AppStrings.Orders.handoffSuccessBody.tr,
          textAlign: TextAlign.center,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          AppFilledButton(
            text: AppStrings.Common.continueLabel.tr,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      );
    },
  );
}

bool isCourierHandoffComplete(ProviderOrderSlice? slice) {
  if (slice == null) return false;
  final w = slice.statusWire;
  return w == ProviderOrderStatusWire.pickedUp ||
      w == ProviderOrderStatusWire.outForDelivery ||
      ProviderOrderStatusWire.isOutgoing(w);
}

class _PickupQrSheetBody extends StatefulWidget {
  const _PickupQrSheetBody({
    required this.masterOrderId,
    required this.providerId,
    this.driverId,
  });

  final String masterOrderId;
  final String providerId;
  final String? driverId;

  @override
  State<_PickupQrSheetBody> createState() => _PickupQrSheetBodyState();
}

class _PickupQrSheetBodyState extends State<_PickupQrSheetBody> {
  bool _closing = false;

  ProviderOrderSlice? _sliceFor(ProviderOrdersState state) {
    for (final order in state.orders) {
      if (order.id != widget.masterOrderId) continue;
      return order.providerSlices[widget.providerId];
    }
    return null;
  }

  void _onHandoffDetected() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProviderOrdersCubit, ProviderOrdersState>(
      listenWhen: (prev, next) {
        final before = isCourierHandoffComplete(_sliceFor(prev));
        final after = isCourierHandoffComplete(_sliceFor(next));
        return !before && after;
      },
      listener: (context, state) => _onHandoffDetected(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.spaceBase,
          AppSizes.spaceSm,
          AppSizes.spaceBase,
          MediaQuery.paddingOf(context).bottom + AppSizes.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              AppStrings.Orders.actionShowPickupQr.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              AppStrings.Orders.detailPickupQrDriverScanHint.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            PickupQrTile(
              masterOrderId: widget.masterOrderId,
              providerId: widget.providerId,
              driverId: widget.driverId,
            ),
          ],
        ),
      ),
    );
  }
}
