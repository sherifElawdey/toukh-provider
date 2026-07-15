import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditDeliveryBody extends StatefulWidget {
  const ReviewEditDeliveryBody({super.key});

  @override
  State<ReviewEditDeliveryBody> createState() => ReviewEditDeliveryBodyState();
}

class ReviewEditDeliveryBodyState extends State<ReviewEditDeliveryBody> {
  late bool _offers;
  late bool _free;
  late DeliveryPricingMode _mode;
  late final TextEditingController _price;
  late final TextEditingController _prep;

  bool _isRestaurant(RegistrationDraft d) =>
      d.kind == ServiceType.restaurant &&
      d.shopCategory == ShopCategory.restaurant;

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    final c = d.deliveryConfig;
    _offers = c?.offersDelivery ?? false;
    _free = c?.isFree ?? true;
    _mode = c?.pricingMode ?? DeliveryPricingMode.fixed;
    _price = TextEditingController(
      text: c?.priceEgp != null && c!.priceEgp! > 0
          ? c.priceEgp.toString()
          : '',
    );
    _prep = TextEditingController(
      text: d.avgPrepMinutes != null && d.avgPrepMinutes! > 0
          ? '${d.avgPrepMinutes}'
          : '',
    );
  }

  @override
  void dispose() {
    _price.dispose();
    _prep.dispose();
    super.dispose();
  }

  DeliveryConfig _buildConfig(RegistrationDraft draft) {
    if (!_offers) {
      return DeliveryConfig(
        offersDelivery: false,
        isFree: true,
        avgPrepMinutes: int.tryParse(_prep.text.replaceAll(RegExp(r'\D'), '')),
      );
    }
    final p = double.tryParse(_price.text.replaceAll(',', '.'));
    return DeliveryConfig(
      offersDelivery: true,
      isFree: _free,
      pricingMode: _free ? null : _mode,
      priceEgp: _free ? null : p,
      avgPrepMinutes: int.tryParse(_prep.text.replaceAll(RegExp(r'\D'), '')),
    );
  }

  bool save(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final draft = cubit.state;
    if (_offers && !_free) {
      final p = double.tryParse(_price.text.replaceAll(',', '.'));
      if (p == null || p <= 0) {
        AppSnack.show(
          context,
          message: AppStrings.Registration.deliveryPriceRequired.tr,
          state: AppSnackState.warning,
          icon: PhosphorIconsRegular.creditCard,
        );
        return false;
      }
    }
    final prep = int.tryParse(_prep.text.replaceAll(RegExp(r'\D'), ''));
    cubit.setDelivery(
      deliveryConfig: _buildConfig(draft),
      avgPrepMinutes: _isRestaurant(draft) ? prep : null,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;
    final restaurant = _isRestaurant(draft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: CustomText(AppStrings.Registration.deliveryOffers),
          value: _offers,
          onChanged: (v) => setState(() => _offers = v),
        ),
        if (_offers) ...[
          SwitchListTile(
            title: CustomText(AppStrings.Registration.reviewDeliveryFree),
            value: _free,
            onChanged: (v) => setState(() => _free = v),
          ),
          if (!_free) ...[
            SegmentedButton<DeliveryPricingMode>(
              segments: [
                ButtonSegment(
                  value: DeliveryPricingMode.fixed,
                  label: CustomText(AppStrings.Registration.deliveryModeFixed),
                ),
                ButtonSegment(
                  value: DeliveryPricingMode.perKm,
                  label: CustomText(AppStrings.Registration.deliveryModePerKm),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            SizedBox(height: AppSizes.spaceMd),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.Registration.deliveryPriceLabel.tr,
              ),
            ),
          ],
        ],
        if (restaurant) ...[
          SizedBox(height: AppSizes.spaceLg),
          TextField(
            controller: _prep,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppStrings.Registration.reviewPrepTime.tr,
            ),
          ),
        ],
      ],
    );
  }
}
