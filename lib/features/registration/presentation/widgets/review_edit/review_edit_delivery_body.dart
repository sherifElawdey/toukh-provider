import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
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
  late DeliveryChoice _delivery;
  late final TextEditingController _prep;

  bool _isRestaurant(RegistrationDraft d) =>
      d.kind == ServiceType.restaurant &&
      d.shopCategory == ShopCategory.restaurant;

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    _delivery = DeliveryChoice.fromConfig(d.deliveryConfig);
    _prep = TextEditingController(
      text: d.avgPrepMinutes != null && d.avgPrepMinutes! > 0
          ? '${d.avgPrepMinutes}'
          : '',
    );
  }

  @override
  void dispose() {
    _prep.dispose();
    super.dispose();
  }

  bool save(BuildContext context) {
    final cubit = context.read<RegistrationCubit>();
    final draft = cubit.state;
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
      deliveryConfig: _delivery.toConfig(avgPrepMinutes: prep),
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
        DeliveryOptionsFields(
          value: _delivery,
          onChanged: (v) => setState(() => _delivery = v),
        ),
        if (restaurant) ...[
          SizedBox(height: AppSizes.spaceLg),
          TextField(
            controller: _prep,
            keyboardType: TextInputType.number,
            inputFormatters: const [EnglishDigitsInputFormatter()],
            decoration: InputDecoration(
              labelText: AppStrings.Registration.reviewPrepTime.tr,
            ),
          ),
        ],
      ],
    );
  }
}
