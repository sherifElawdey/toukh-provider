import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/utils/english_price_input.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Fee inputs for a store's own delivery: fixed, per km, or by region
/// (one fee within the city, another outside it).
class DeliveryPricingFields extends StatelessWidget {
  const DeliveryPricingFields({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.price,
    required this.innerCity,
    required this.outerCity,
  });

  final DeliveryPricingMode mode;
  final ValueChanged<DeliveryPricingMode> onModeChanged;

  /// Fixed fee, or the per-km rate.
  final TextEditingController price;
  final TextEditingController innerCity;
  final TextEditingController outerCity;

  static String get _km => kStoreCityRadiusKm.toStringAsFixed(0);

  Widget _feeField(
    TextEditingController controller, {
    required String label,
    String? note,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: EnglishPriceInput.formatters,
      decoration: InputDecoration(
        labelText: label,
        helperText: note,
        helperMaxLines: 2,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DeliveryPricingMode>(
          showSelectedIcon: false,
          segments: [
            for (final (value, label) in [
              (
                DeliveryPricingMode.fixed,
                AppStrings.Registration.deliveryModeFixed,
              ),
              (
                DeliveryPricingMode.perKm,
                AppStrings.Registration.deliveryModePerKm,
              ),
              (
                DeliveryPricingMode.byRegion,
                AppStrings.Registration.deliveryModeByRegion,
              ),
            ])
              ButtonSegment(value: value, label: CustomText(label)),
          ],
          selected: {mode},
          onSelectionChanged: (s) => onModeChanged(s.first),
        ),
        SizedBox(height: AppSizes.spaceMd),
        if (mode == DeliveryPricingMode.byRegion) ...[
          _feeField(
            innerCity,
            label: AppStrings.Registration.deliveryInnerCityLabel.tr,
            note: AppStrings.Registration.deliveryInnerCityNote.trParams({
              'km': _km,
            }),
            icon: PhosphorIconsRegular.buildings,
          ),
          SizedBox(height: AppSizes.spaceMd),
          _feeField(
            outerCity,
            label: AppStrings.Registration.deliveryOuterCityLabel.tr,
            note: AppStrings.Registration.deliveryOuterCityNote.trParams({
              'km': _km,
            }),
            icon: PhosphorIconsRegular.path,
          ),
        ] else
          _feeField(
            price,
            label: mode == DeliveryPricingMode.perKm
                ? AppStrings.Registration.deliveryPricePerKmLabel.tr
                : AppStrings.Registration.deliveryPriceLabel.tr,
          ),
      ],
    );
  }
}

/// Paid-delivery fees read from [DeliveryPricingFields]' controllers.
class DeliveryPricingInput {
  DeliveryPricingInput({
    required this.mode,
    required TextEditingController price,
    required TextEditingController innerCity,
    required TextEditingController outerCity,
  }) : price = _parse(price),
       innerCity = _parse(innerCity),
       outerCity = _parse(outerCity);

  final DeliveryPricingMode mode;
  final double? price;
  final double? innerCity;
  final double? outerCity;

  static double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  bool get _byRegion => mode == DeliveryPricingMode.byRegion;

  /// Translation key of what's missing, or null when the fees are usable.
  String? get errorKey {
    bool ok(double? v) => v != null && v > 0;
    if (_byRegion) {
      return ok(innerCity) && ok(outerCity)
          ? null
          : AppStrings.Registration.deliveryRegionRequired;
    }
    return ok(price) ? null : AppStrings.Registration.deliveryPriceRequired;
  }

  /// Paid [DeliveryConfig] with these fees. By region also stores the
  /// in-city fee as `priceEgp`, so app versions that only know a single
  /// price still show a sensible starting fee.
  DeliveryConfig toConfig({
    required bool manageFromAccount,
    int? avgPrepMinutes,
  }) {
    return DeliveryConfig(
      offersDelivery: true,
      isFree: false,
      manageFromAccount: manageFromAccount,
      pricingMode: mode,
      priceEgp: _byRegion ? innerCity : price,
      innerCityFeeEgp: _byRegion ? innerCity : null,
      outerCityFeeEgp: _byRegion ? outerCity : null,
      avgPrepMinutes: avgPrepMinutes,
    );
  }
}

/// Text for a fee field, or empty when unset.
String deliveryFeeText(double? v) {
  if (v == null || v <= 0) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// "Paid delivery: 15 EGP within the city, 30 EGP outside".
String byRegionDeliverySummary(DeliveryConfig c) {
  String fee(double? v) {
    final t = deliveryFeeText(v);
    return t.isEmpty ? '—' : t;
  }

  return AppStrings.Registration.reviewDeliveryByRegion.trParams({
    'inner': fee(c.innerCityFeeEgp),
    'outer': fee(c.outerCityFeeEgp),
  });
}
