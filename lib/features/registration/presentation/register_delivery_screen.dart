import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/delivery_pricing_fields.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterDeliveryScreen extends StatefulWidget {
  const RegisterDeliveryScreen({super.key});

  @override
  State<RegisterDeliveryScreen> createState() => _RegisterDeliveryScreenState();
}

class _RegisterDeliveryScreenState extends State<RegisterDeliveryScreen> {
  DeliveryChoice _delivery = const DeliveryChoice();
  final _prep = TextEditingController();

  /// Optional support / delivery number shown with every order.
  final _support = TextEditingController();
  bool _seededSupport = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededSupport) return;
    _seededSupport = true;
    final draft = context.read<RegistrationCubit>().state;
    _delivery = DeliveryChoice.fromConfig(draft.deliveryConfig);
    final ten = egyptTenDigitsFromStored(draft.supportPhone);
    if (ten != null) _support.text = egyptLocalElevenFromTen(ten);
  }

  /// E.164 of the entered number; '' when empty; null when invalid.
  String? get _supportE164 {
    final digits = _support.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final e164 = egyptMobileE164(digits);
    return e164.isEmpty ? null : e164;
  }

  bool _isRestaurant(RegistrationDraft d) =>
      d.kind == ServiceType.restaurant &&
      d.shopCategory == ShopCategory.restaurant;

  @override
  void dispose() {
    _prep.dispose();
    _support.dispose();
    super.dispose();
  }

  void _next() {
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
      return;
    }
    final support = _supportE164;
    if (support == null) {
      AppSnack.show(
        context,
        message: AppStrings.Auth.invalidPhone.tr,
        state: AppSnackState.warning,
        icon: PhosphorIconsRegular.phone,
      );
      return;
    }
    cubit.setDelivery(
      deliveryConfig: _delivery.toConfig(avgPrepMinutes: prep),
      avgPrepMinutes: _isRestaurant(draft) ? prep : null,
      supportPhone: support.isEmpty ? null : support,
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
          child: DeliveryOptionsFields(
            value: _delivery,
            onChanged: (v) => setState(() => _delivery = v),
          ),
        ),
        RegistrationSectionCard(
          icon: PhosphorIconsDuotone.phoneCall,
          title: AppStrings.Registration.supportPhoneTitle,
          hint: AppStrings.Registration.supportPhoneHint,
          child: AppPhoneField(
            controller: _support,
            label: AppStrings.Registration.supportPhoneLabel,
            invalidTenDigitsMessage: AppStrings.Auth.invalidPhone,
            validator: (_) => null,
            textInputAction: TextInputAction.done,
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
              inputFormatters: const [EnglishDigitsInputFormatter()],
              decoration: InputDecoration(
                labelText: AppStrings.Registration.reviewPrepTime.tr,
              ),
            ),
          ),
      ],
    );
  }
}
