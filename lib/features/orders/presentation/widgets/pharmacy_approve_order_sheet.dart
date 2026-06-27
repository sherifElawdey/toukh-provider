import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/network_image_zoom_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Bottom inset for snacks shown from modal sheets over the provider shell nav.
const _kShellSnackBottomInset = 100.0;

Future<bool?> showPharmacyApproveOrderSheet(
  BuildContext context, {
  required ProviderMasterOrderRow row,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => BlocProvider.value(
      value: getIt<ProviderOrdersCubit>(),
      child: _PharmacyApproveOrderSheet(row: row),
    ),
  );
}

class _PharmacyApproveOrderSheet extends StatefulWidget {
  const _PharmacyApproveOrderSheet({required this.row});

  final ProviderMasterOrderRow row;

  @override
  State<_PharmacyApproveOrderSheet> createState() =>
      _PharmacyApproveOrderSheetState();
}

class _PharmacyApproveOrderSheetState extends State<_PharmacyApproveOrderSheet> {
  final _note = TextEditingController();
  final _subtotal = TextEditingController();
  late final Set<String> _approvedIds;
  late final double _deliveryFee;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final items = widget.row.slice.items;
    _approvedIds = {
      for (final item in items)
        if ((item.requestItemId ?? item.itemId ?? item.name).isNotEmpty)
          item.requestItemId ?? item.itemId ?? item.name,
    };
    final auth = context.read<AuthCubit>().state;
    final dc = auth is Authenticated ? auth.profile.deliveryConfig : null;
    _deliveryFee = dc?.isFree == true ? 0 : (dc?.priceEgp ?? 0);
    _subtotal.text = '0';
  }

  @override
  void dispose() {
    _note.dispose();
    _subtotal.dispose();
    super.dispose();
  }

  List<ProviderOrderSliceLineItem> get _items => widget.row.slice.items;

  bool get _isItemOrder => _items.isNotEmpty;

  String? get _prescriptionUrl =>
      widget.row.slice.prescriptionImageUrl ??
      widget.row.master.pharmacyRequest?.prescriptionImageUrl;

  void _showSnack(String message, {AppSnackState state = AppSnackState.error}) {
    AppSnack.show(
      context,
      message: message,
      state: state,
      bottomInset: _kShellSnackBottomInset,
    );
  }

  Future<void> _submit() async {
    final subtotal = double.tryParse(_subtotal.text.replaceAll(',', '').trim());
    if (subtotal == null || subtotal < 0) {
      _showSnack(AppStrings.Orders.pharmacyQuoteSubtotalRequired.tr);
      return;
    }
    if (_isItemOrder && _approvedIds.isEmpty) {
      _showSnack(AppStrings.Orders.pharmacyQuoteSelectItems.tr);
      return;
    }

    setState(() => _submitting = true);
    final cubit = context.read<ProviderOrdersCubit>();
    await cubit.approvePharmacyRequest(
          orderId: widget.row.id,
          pharmacistNote: _note.text.trim(),
          approvedItemIds: _approvedIds.toList(),
          quotedSubtotalEgp: subtotal,
          quotedDeliveryFeeEgp: _deliveryFee,
        );
    if (!mounted) return;
    final err = cubit.state.errorMessage;
    if (err != null) {
      _showSnack(err);
      setState(() => _submitting = false);
      return;
    }
    Navigator.pop(context, true);
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.spaceBase,
        AppSizes.spaceSm,
        AppSizes.spaceBase,
        bottom + AppSizes.spaceBase,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              AppStrings.Orders.pharmacyApproveTitle.tr,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            if (_prescriptionUrl != null && _prescriptionUrl!.isNotEmpty) ...[
              TappableNetworkImage(
                imageUrl: _prescriptionUrl!,
                height: 160,
                width: double.infinity,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              const SizedBox(height: AppSizes.spaceMd),
            ],
            if (_isItemOrder)
              ..._items.map((item) {
                final id = item.requestItemId ?? item.itemId ?? item.name;
                final checked = _approvedIds.contains(id);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _approvedIds.add(id);
                      } else {
                        _approvedIds.remove(id);
                      }
                    });
                  },
                  title: CustomText(item.name),
                  subtitle: CustomText(item.displayQuantity),
                  secondary: item.imageUrl != null
                      ? TappableNetworkImage(
                          imageUrl: item.imageUrl!,
                          width: 40,
                          height: 40,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        )
                      : null,
                  contentPadding: EdgeInsets.zero,
                );
              }),
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              AppStrings.Orders.pharmacyPharmacistNote.tr,
              style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.spaceXs),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AppStrings.Orders.pharmacyPharmacistNoteHint.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            TextField(
              controller: _subtotal,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppStrings.Orders.pharmacyQuoteSubtotal.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              AppStrings.Orders.pharmacyQuoteDeliveryFee.trParams({
                'fee': _deliveryFee.toStringAsFixed(0),
              }),
              style: t.bodySmall,
            ),
            const SizedBox(height: AppSizes.spaceLg),
            AppFilledButton(
              text: AppStrings.Orders.pharmacyAcceptOrder.tr,
              status: _submitting
                  ? AppButtonStatus.loading
                  : AppButtonStatus.enabled,
              onTap: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
