import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/store_courier/data/store_courier_repository.dart';
import 'package:toukh_provider/features/store_courier/presentation/courier_destination_picker_screen.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// "Request a courier to deliver your order": where to, who receives it,
/// what the courier collects. Havit prices the delivery from the store to
/// the address, and the store pays it to the courier in cash at pickup.
class RequestCourierScreen extends StatefulWidget {
  const RequestCourierScreen({super.key});

  @override
  State<RequestCourierScreen> createState() => _RequestCourierScreenState();
}

class _RequestCourierScreenState extends State<RequestCourierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _details = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();

  CourierDestination? _destination;
  CourierPaymentMethod _payment = CourierPaymentMethod.cash;
  CourierQuote? _quote;
  bool _quoting = false;
  String? _quoteError;
  bool _submitting = false;
  Timer? _priceDebounce;
  int _quoteGen = 0;

  StoreCourierRepository get _repo => getIt<StoreCourierRepository>();

  @override
  void dispose() {
    _priceDebounce?.cancel();
    _details.dispose();
    _name.dispose();
    _phone.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _orderPrice =>
      double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;

  /// What the courier collects from the recipient.
  double get _collect =>
      _payment == CourierPaymentMethod.cash ? _orderPrice : 0;

  LatLng _mapStart() {
    final d = _destination;
    if (d != null) return LatLng(d.lat, d.lng);
    final auth = context.read<AuthCubit>().state;
    if (auth is Authenticated) {
      final lat = auth.profile.lat;
      final lng = auth.profile.lng;
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return const LatLng(30.0444, 31.2357);
  }

  Future<void> _pickDestination() async {
    final picked = await CourierDestinationPickerScreen.open(
      context,
      start: _mapStart(),
    );
    if (picked == null || !mounted) return;
    setState(() => _destination = picked);
    unawaited(_refreshQuote());
  }

  void _onPriceChanged(String _) {
    _priceDebounce?.cancel();
    _priceDebounce = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_refreshQuote()),
    );
  }

  Future<void> _refreshQuote() async {
    final destination = _destination;
    if (destination == null) return;
    final gen = ++_quoteGen;
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final quote = await _repo.quote(
        destination: destination,
        orderPriceEgp: _orderPrice,
      );
      if (!mounted || gen != _quoteGen) return;
      setState(() => _quote = quote);
    } catch (e) {
      if (!mounted || gen != _quoteGen) return;
      setState(() {
        _quote = null;
        _quoteError = appFirebaseError(e);
      });
    } finally {
      if (mounted && gen == _quoteGen) setState(() => _quoting = false);
    }
  }

  Future<void> _submit() async {
    final destination = _destination;
    if (destination == null) {
      AppSnack.show(
        context,
        message: AppStrings.StoreCourier.destinationRequired.tr,
        state: AppSnackState.warning,
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final quote = _quote;
    if (quote == null) {
      unawaited(_refreshQuote());
      return;
    }
    setState(() => _submitting = true);
    try {
      final orderId = await _repo.create(
        destination: destination.copyWith(details: _details.text),
        orderPriceEgp: _orderPrice,
        recipientPhone: _phone.text,
        paymentMethod: _payment,
        recipientName: _name.text,
        note: _note.text,
      );
      if (!mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.StoreCourier.created.tr,
        state: AppSnackState.success,
      );
      context.pushReplacement(AppRoutes.orderDetailPath(orderId));
    } on Object catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: appFirebaseError(e),
        state: AppSnackState.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quote = _quote;
    return Scaffold(
      appBar: AppBar(title: CustomText(AppStrings.StoreCourier.title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSizes.screenPadding.copyWith(
            top: AppSizes.spaceLg,
            bottom: AppSizes.space2xl,
          ),
          children: [
            CustomText(
              AppStrings.StoreCourier.intro,
              style: TextStyle(
                color: AppColors.muted(context),
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSizes.spaceLg),
            _SectionTitle(AppStrings.StoreCourier.destinationTitle),
            const SizedBox(height: AppSizes.spaceSm),
            _DestinationTile(
              destination: _destination,
              onTap: _pickDestination,
            ),
            const SizedBox(height: AppSizes.spaceMd),
            AppTextField(
              controller: _details,
              labelText: AppStrings.StoreCourier.addressDetails,
              hintText: AppStrings.StoreCourier.addressDetailsHint,
              maxLines: 2,
              maxLength: 300,
            ),
            const SizedBox(height: AppSizes.spaceLg),
            _SectionTitle(AppStrings.StoreCourier.recipientTitle),
            const SizedBox(height: AppSizes.spaceSm),
            AppTextField(
              controller: _phone,
              labelText: AppStrings.StoreCourier.recipientPhone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                LengthLimitingTextInputFormatter(15),
              ],
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                return digits.length < 8
                    ? AppStrings.StoreCourier.recipientPhoneRequired.tr
                    : null;
              },
            ),
            const SizedBox(height: AppSizes.spaceMd),
            AppTextField(
              controller: _name,
              labelText: AppStrings.StoreCourier.recipientName,
              maxLength: 80,
            ),
            const SizedBox(height: AppSizes.spaceLg),
            _SectionTitle(AppStrings.StoreCourier.orderTitle),
            const SizedBox(height: AppSizes.spaceSm),
            AppTextField(
              controller: _price,
              labelText: AppStrings.StoreCourier.orderPrice,
              hintText: _payment == CourierPaymentMethod.cash
                  ? AppStrings.StoreCourier.orderPriceHint
                  : AppStrings.StoreCourier.orderPricePrepaidHint,
              suffixText: AppStrings.Common.egp,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: _onPriceChanged,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null; // nothing to collect
                final n = double.tryParse(t);
                return n == null || n < 0
                    ? AppStrings.StoreCourier.orderPriceInvalid.tr
                    : null;
              },
            ),
            const SizedBox(height: AppSizes.spaceMd),
            CustomText(
              AppStrings.StoreCourier.paymentTitle,
              style: TextStyle(
                fontSize: AppSizes.fontCaption,
                fontWeight: FontWeight.w700,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            _PaymentOption(
              icon: PhosphorIconsDuotone.money,
              title: AppStrings.StoreCourier.paymentCash,
              subtitle: AppStrings.StoreCourier.paymentCashHint,
              selected: _payment == CourierPaymentMethod.cash,
              onTap: () => setState(() => _payment = CourierPaymentMethod.cash),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            _PaymentOption(
              icon: PhosphorIconsDuotone.checkCircle,
              title: AppStrings.StoreCourier.paymentPrepaid,
              subtitle: AppStrings.StoreCourier.paymentPrepaidHint,
              selected: _payment == CourierPaymentMethod.prepaid,
              onTap: () =>
                  setState(() => _payment = CourierPaymentMethod.prepaid),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            AppTextField(
              controller: _note,
              labelText: AppStrings.StoreCourier.note,
              hintText: AppStrings.StoreCourier.noteHint,
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: AppSizes.spaceLg),
            _FeeCard(
              hasDestination: _destination != null,
              quoting: _quoting,
              quote: quote,
              error: _quoteError,
              orderPriceEgp: _collect,
              onRetry: _refreshQuote,
            ),
            const SizedBox(height: AppSizes.spaceLg),
            AppFilledButton(
              text: quote == null
                  ? AppStrings.StoreCourier.submit.tr
                  : AppStrings.StoreCourier.submitWithFee.trParams({
                      'fee': _money(quote.deliveryFeeEgp),
                    }),
              icon: PhosphorIconsRegular.moped,
              status: _submitting
                  ? AppButtonStatus.loading
                  : (_destination == null || _quoting || quote == null)
                  ? AppButtonStatus.disabled
                  : AppButtonStatus.enabled,
              onTap: _submit,
            ),
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              AppStrings.StoreCourier.noCodeNote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontCaption,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double v) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  return AppStrings.Common.egpAmount.trParams({'amount': s});
}

/// One answer of the payment method choice.
class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.secondColor;
    final radius = BorderRadius.circular(AppSizes.radiusMd);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.tint(context, accent) : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spaceMd),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? accent : scheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: selected ? accent : AppColors.muted(context)),
                const SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppSizes.fontCaption,
                          height: 1.4,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.circle,
                  size: 20,
                  color: selected ? accent : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.textKey);

  final String textKey;

  @override
  Widget build(BuildContext context) {
    return CustomText(
      textKey,
      style: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.destination, required this.onTap});

  final CourierDestination? destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picked = destination;
    final radius = BorderRadius.circular(AppSizes.radiusMd);
    return Material(
      color: picked == null
          ? AppColors.tint(context, AppColors.secondColor)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Row(
            children: [
              Icon(PhosphorIconsDuotone.mapPinLine, color: AppColors.secondColor),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: CustomText(
                  picked == null
                      ? AppStrings.StoreCourier.pickDestination.tr
                      : picked.formattedAddress,
                  maxLines: 3,
                  style: TextStyle(
                    fontWeight: picked == null ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceSm),
              CustomText(
                picked == null
                    ? AppStrings.StoreCourier.choose
                    : AppStrings.StoreCourier.change,
                style: TextStyle(
                  color: AppColors.secondColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delivery fee (Havit pricing, paid to the courier in cash) and what the
/// courier collects from the recipient.
class _FeeCard extends StatelessWidget {
  const _FeeCard({
    required this.hasDestination,
    required this.quoting,
    required this.quote,
    required this.error,
    required this.orderPriceEgp,
    required this.onRetry,
  });

  final bool hasDestination;
  final bool quoting;
  final CourierQuote? quote;
  final String? error;
  final double orderPriceEgp;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = quote;
    Widget row(String label, String value, {bool strong = false, Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: CustomText(
                label,
                style: TextStyle(color: AppColors.muted(context)),
              ),
            ),
            CustomText(
              value,
              style: TextStyle(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    Widget body;
    if (!hasDestination) {
      body = CustomText(
        AppStrings.StoreCourier.feeNeedsDestination,
        style: TextStyle(color: AppColors.muted(context)),
      );
    } else if (quoting && q == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.spaceSm),
        child: LinearProgressIndicator(),
      );
    } else if (q == null) {
      body = Row(
        children: [
          Expanded(
            child: CustomText(
              error ?? AppStrings.Common.unknownError.tr,
              style: TextStyle(color: scheme.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: CustomText(AppStrings.Common.retry),
          ),
        ],
      );
    } else {
      final km = q.distanceMeters / 1000;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            AppStrings.StoreCourier.feeLabel.tr,
            _money(q.deliveryFeeEgp),
            strong: true,
          ),
          if (km > 0)
            row(
              AppStrings.StoreCourier.distance.tr,
              AppStrings.StoreCourier.distanceKm.trParams({
                'km': km.toStringAsFixed(1),
              }),
            ),
          row(AppStrings.StoreCourier.collectLabel.tr, _money(orderPriceEgp)),
          const SizedBox(height: AppSizes.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PhosphorIconsRegular.money,
                size: 18,
                color: AppColors.secondColor,
              ),
              const SizedBox(width: AppSizes.spaceXs),
              Expanded(
                child: CustomText(
                  AppStrings.StoreCourier.feeCashNote.trParams({
                    'fee': _money(q.deliveryFeeEgp),
                  }),
                  style: TextStyle(
                    fontSize: AppSizes.fontCaption,
                    height: 1.45,
                    color: AppColors.muted(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsDuotone.calculator, color: AppColors.secondColor),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: CustomText(
                  AppStrings.StoreCourier.feeTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (quoting && q != null)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceSm),
          body,
        ],
      ),
    );
  }
}
