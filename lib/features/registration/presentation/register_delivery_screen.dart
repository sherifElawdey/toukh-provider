import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/utils/english_price_input.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterDeliveryScreen extends StatefulWidget {
  const RegisterDeliveryScreen({super.key});

  @override
  State<RegisterDeliveryScreen> createState() => _RegisterDeliveryScreenState();
}

class _RegisterDeliveryScreenState extends State<RegisterDeliveryScreen> {
  bool _offers = false;
  bool _manageFromAccount = false;
  bool _free = false;
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
        isFree: _free,
        manageFromAccount: _manageFromAccount,
        avgPrepMinutes: int.tryParse(_prep.text.replaceAll(RegExp(r'\D'), '')),
      );
    }
    final p = double.tryParse(_price.text.replaceAll(',', '.'));
    return DeliveryConfig(
      offersDelivery: true,
      isFree: _free,
      manageFromAccount: _manageFromAccount,
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
    if (_isRestaurant(draft) && (prep == null || prep <= 0)) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.prepTimeRequired.tr,
        state: AppSnackState.warning,
        icon: PhosphorIconsRegular.timer,
      );
      return;
    }
    cubit.setDelivery(
      deliveryConfig: _buildConfig(),
      avgPrepMinutes: _isRestaurant(draft) ? prep : null,
    );
    context.push(
      _isRestaurant(draft)
          ? AppRoutes.registerCuisine
          : AppRoutes.registerReview,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;
    if (draft.kind == ServiceType.homeService) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.pushReplacement(AppRoutes.registerReview);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final restaurant = _isRestaurant(draft);
    final scheme = Theme.of(context).colorScheme;
    final noteStyle = TextStyle(
      fontSize: AppSizes.fontCaption,
      height: 1.45,
      color: AppColors.muted(context),
    );
    Widget toggle({
      required String title,
      String? subtitle,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        activeThumbColor: AppColors.secondColor,
        title: CustomText(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle == null
            ? null
            : CustomText(subtitle, style: noteStyle),
        value: value,
        onChanged: onChanged,
      );
    }

    return RegistrationStepScaffold(
      stage: RegistrationStage.place,
      icon: PhosphorIconsDuotone.moped,
      title: AppStrings.Registration.deliveryTitle,
      subtitle: AppStrings.Registration.deliverySubtitle,
      onNext: _next,
      children: [
        RegistrationSectionCard(
          icon: PhosphorIconsDuotone.moped,
          title: AppStrings.Registration.secOwnDeliveryTitle,
          hint: AppStrings.Registration.secOwnDeliveryHint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              toggle(
                title: AppStrings.Registration.deliveryOffers,
                value: _offers,
                onChanged: (v) => setState(() => _offers = v),
              ),
              toggle(
                title: AppStrings.Registration.deliveryManageFromAccount,
                subtitle: AppStrings.Registration.deliveryManageFromAccountHint,
                value: _manageFromAccount,
                onChanged: (v) => setState(() => _manageFromAccount = v),
              ),
              toggle(
                title: AppStrings.Registration.reviewDeliveryFree,
                value: _free,
                onChanged: (v) => setState(() => _free = v),
              ),
              if (!_offers)
                Container(
                  margin: const EdgeInsets.only(top: AppSizes.spaceSm),
                  padding: const EdgeInsets.all(AppSizes.spaceMd),
                  decoration: BoxDecoration(
                    color: AppColors.tint(context, AppColors.secondColor),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        PhosphorIconsRegular.info,
                        size: 18,
                        color: AppColors.secondColor,
                      ),
                      SizedBox(width: AppSizes.spaceSm),
                      Expanded(
                        child: CustomText(
                          AppStrings.Registration.deliveryHavitFeeNote,
                          style: noteStyle.copyWith(color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_offers && !_free) ...[
                SizedBox(height: AppSizes.spaceMd),
                CustomText(
                  AppStrings.Registration.deliveryOwnPriceNote,
                  style: noteStyle,
                ),
                SizedBox(height: AppSizes.spaceSm),
                SegmentedButton<DeliveryPricingMode>(
                  segments: [
                    ButtonSegment(
                      value: DeliveryPricingMode.fixed,
                      label: CustomText(
                        AppStrings.Registration.deliveryModeFixed,
                      ),
                    ),
                    ButtonSegment(
                      value: DeliveryPricingMode.perKm,
                      label: CustomText(
                        AppStrings.Registration.deliveryModePerKm,
                      ),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                SizedBox(height: AppSizes.spaceMd),
                TextField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: EnglishPriceInput.formatters,
                  decoration: InputDecoration(
                    labelText: _mode == DeliveryPricingMode.perKm
                        ? AppStrings.Registration.deliveryPricePerKmLabel.tr
                        : AppStrings.Registration.deliveryPriceLabel.tr,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (restaurant)
          RegistrationSectionCard(
            icon: PhosphorIconsDuotone.clockCountdown,
            title: AppStrings.Registration.secPrepTitle,
            hint: AppStrings.Registration.secPrepHint,
            child: TextField(
              controller: _prep,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.Registration.reviewPrepTime.tr,
              ),
            ),
          ),
      ],
    );
  }
}
