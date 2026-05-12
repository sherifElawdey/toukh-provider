import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterDeliveryScreen extends StatefulWidget {
  const RegisterDeliveryScreen({super.key});

  @override
  State<RegisterDeliveryScreen> createState() =>
      _RegisterDeliveryScreenState();
}

class _RegisterDeliveryScreenState extends State<RegisterDeliveryScreen> {
  bool _offers = false;
  bool _free = true;
  DeliveryPricingMode _mode = DeliveryPricingMode.fixed;
  final _price = TextEditingController();
  final _prep = TextEditingController();

  bool _isRestaurant(RegistrationDraft d) =>
      d.kind == ServiceType.restaurant &&
      d.shopCategory == ShopCategory.restaurant;

  @override
  void dispose() {
    _price.dispose();
    _prep.dispose();
    super.dispose();
  }

  DeliveryConfig _buildConfig() {
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

  void _next() {
    final cubit = context.read<RegistrationCubit>();
    final draft = cubit.state;
    final prep = int.tryParse(_prep.text.replaceAll(RegExp(r'\D'), ''));
    cubit.setDelivery(
      deliveryConfig: _buildConfig(),
      avgPrepMinutes: _isRestaurant(draft) ? prep : null,
    );
    context.push(AppRoutes.registerReview);
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;
    final restaurant = _isRestaurant(draft);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Registration.deliveryTitle),
      ),
      body: ListView(
        padding: AppSizes.screenPadding,
        children: [
          Center(
            child: ToukhServiceLogo(
              size: 56,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          SizedBox(height: AppSizes.spaceMd),
          SwitchListTile(
            title: CustomText('Offers delivery'),
            value: _offers,
            onChanged: (v) => setState(() => _offers = v),
          ),
          if (_offers) ...[
            SwitchListTile(
              title: CustomText('Free delivery'),
              value: _free,
              onChanged: (v) => setState(() => _free = v),
            ),
            if (!_free) ...[
              SegmentedButton<DeliveryPricingMode>(
                segments: [
                  ButtonSegment(
                    value: DeliveryPricingMode.fixed,
                    label: CustomText('Fixed'),
                  ),
                  ButtonSegment(
                    value: DeliveryPricingMode.perKm,
                    label: CustomText('Per km'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (s) =>
                    setState(() => _mode = s.first),
              ),
              SizedBox(height: AppSizes.spaceMd),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (EGP)',
                ),
              ),
            ],
          ],
          if (restaurant) ...[
            SizedBox(height: AppSizes.spaceLg),
            TextField(
              controller: _prep,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Avg prep time (minutes)',
              ),
            ),
          ],
          SizedBox(height: AppSizes.spaceXl),
          RegistrationStepNavFooter(
            useSafeArea: false,
            padding: EdgeInsets.zero,
            onBack: () => context.pop(),
            onNext: _next,
          ),
        ],
      ),
    );
  }
}
