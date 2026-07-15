import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
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
    if (_offers && !_free) {
      final p = double.tryParse(_price.text.replaceAll(',', '.'));
      if (p == null || p <= 0) {
        AppSnack.show(
          context,
          message: AppStrings.Registration.deliveryPriceRequired.tr,
          state: AppSnackState.warning,
          icon: PhosphorIconsRegular.creditCard,
        );
        return;
      }
    }
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
    if (draft.kind == ServiceType.homeService) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.pushReplacement(AppRoutes.registerReview);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final restaurant = _isRestaurant(draft);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
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
                onSelectionChanged: (s) =>
                    setState(() => _mode = s.first),
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
