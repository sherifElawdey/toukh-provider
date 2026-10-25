import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/delivery_pricing_fields.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditDeliveryBody extends StatefulWidget {
  const ReviewEditDeliveryBody({super.key});

  @override
  State<ReviewEditDeliveryBody> createState() => ReviewEditDeliveryBodyState();
}

class ReviewEditDeliveryBodyState extends State<ReviewEditDeliveryBody> {
  late bool _offers;
  late bool _manageFromAccount;
  late bool _free;
  late DeliveryPricingMode _mode;
  late final TextEditingController _price;
  late final TextEditingController _innerCity;
  late final TextEditingController _outerCity;
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
    _manageFromAccount = c?.manageFromAccount ?? false;
    _free = c?.isFree ?? false;
    _mode = c?.pricingMode ?? DeliveryPricingMode.fixed;
    _price = TextEditingController(text: deliveryFeeText(c?.priceEgp));
    _innerCity = TextEditingController(
      text: deliveryFeeText(c?.innerCityFeeEgp),
    );
    _outerCity = TextEditingController(
      text: deliveryFeeText(c?.outerCityFeeEgp),
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
    _innerCity.dispose();
    _outerCity.dispose();
    _prep.dispose();
    super.dispose();
  }

  DeliveryPricingInput get _fees => DeliveryPricingInput(
    mode: _mode,
    price: _price,
    innerCity: _innerCity,
    outerCity: _outerCity,
  );

  DeliveryConfig _buildConfig(RegistrationDraft draft) {
    final prep = int.tryParse(_prep.text.replaceAll(RegExp(r'\D'), ''));
    if (_offers && !_free) {
      return _fees.toConfig(
        manageFromAccount: _manageFromAccount,
        avgPrepMinutes: prep,
      );
    }
    return DeliveryConfig(
      offersDelivery: _offers,
      isFree: _free,
      manageFromAccount: _manageFromAccount,
      avgPrepMinutes: prep,
    );
  }

  bool save(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final draft = cubit.state;
    if (_offers && !_free) {
      final error = _fees.errorKey;
      if (error != null) {
        AppSnack.show(
          context,
          message: error.tr,
          state: AppSnackState.warning,
          icon: PhosphorIconsRegular.creditCard,
        );
        return false;
      }
    }
    final prep = int.tryParse(_prep.text.replaceAll(RegExp(r'\D'), ''));
    if (_isRestaurant(draft) && (prep == null || prep <= 0)) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.prepTimeRequired.tr,
        state: AppSnackState.warning,
        icon: PhosphorIconsRegular.timer,
      );
      return false;
    }
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
        SwitchListTile(
          title: CustomText(AppStrings.Registration.deliveryManageFromAccount),
          subtitle: CustomText(
            AppStrings.Registration.deliveryManageFromAccountHint,
          ),
          value: _manageFromAccount,
          onChanged: (v) => setState(() => _manageFromAccount = v),
        ),
        if (_offers) ...[
          SwitchListTile(
            title: CustomText(AppStrings.Registration.reviewDeliveryFree),
            value: _free,
            onChanged: (v) => setState(() => _free = v),
          ),
          if (!_free)
            DeliveryPricingFields(
              mode: _mode,
              onModeChanged: (m) => setState(() => _mode = m),
              price: _price,
              innerCity: _innerCity,
              outerCity: _outerCity,
            ),
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
