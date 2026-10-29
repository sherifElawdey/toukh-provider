import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/twilio/twilio_otp_errors.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/delivery_pricing_fields.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/working_hours_form.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/otp_delivery_snack.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/features/auth/registration_otp_args_holder.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/register_review_edit_sheet.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/register_review_tile.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

String _kindKey(ServiceType k) {
  switch (k) {
    case ServiceType.restaurant:
      return AppStrings.Registration.kindRestaurant;
    case ServiceType.homeService:
      return AppStrings.Registration.kindHomeService;
    case ServiceType.supermarket:
      return AppStrings.Registration.kindSupermarket;
    case ServiceType.grocery:
      return AppStrings.Registration.kindGrocery;
    case ServiceType.homeBrands:
      return AppStrings.Registration.kindHomeBrands;
    case ServiceType.pharmacy:
      return AppStrings.Registration.kindPharmacy;
    case ServiceType.otherShops:
      return AppStrings.Registration.kindOtherShops;
  }
}

String _shopCatLabel(ShopCategory c) {
  switch (c) {
    case ShopCategory.pharmacy:
      return 'registration.shop_pharmacy'.tr;
    case ShopCategory.supermarket:
      return 'registration.shop_supermarket'.tr;
    case ShopCategory.fruitVeg:
      return 'registration.shop_fruit_veg'.tr;
    case ShopCategory.restaurant:
      return 'registration.shop_restaurant'.tr;
  }
}

(String titleKey, String value)? _categoryEntry(RegistrationDraft d) {
  final k = d.kind;
  if (k == ServiceType.homeService &&
      d.serviceCategoryId != null &&
      d.serviceCategoryId!.trim().isNotEmpty) {
    final title = d.serviceCategoryTitle?.trim();
    return (
      AppStrings.Registration.serviceCategoryTitle,
      (title != null && title.isNotEmpty) ? title : d.serviceCategoryId!.trim(),
    );
  }
  final sc = d.shopCategory;
  if (sc != null &&
      (k == ServiceType.restaurant ||
          k == ServiceType.supermarket ||
          k == ServiceType.pharmacy ||
          k == ServiceType.grocery)) {
    return (AppStrings.Registration.shopCategoryTitle, _shopCatLabel(sc));
  }
  return null;
}

String _hoursSummary(RegistrationDraft d) {
  return summarizeWorkingHours(d.workingHours);
}

String? _deliverySummary(RegistrationDraft d) {
  if (d.kind == ServiceType.homeService) return null;
  final c = d.deliveryConfig;
  if (c == null) return AppStrings.Registration.reviewDeliveryNotSet.tr;
  if (!c.offersDelivery) {
    return AppStrings.Registration.reviewDeliveryNone.tr;
  }
  if (c.isFree) return AppStrings.Registration.reviewDeliveryFree.tr;
  if (c.pricingMode == DeliveryPricingMode.byRegion) {
    return byRegionDeliverySummary(c);
  }
  final p = c.priceEgp;
  final mode = c.pricingMode == DeliveryPricingMode.perKm
      ? AppStrings.Registration.deliveryModePerKm.tr
      : AppStrings.Registration.deliveryModeFixed.tr;
  final priceStr = p != null && p > 0
      ? (p == p.roundToDouble() ? p.toInt().toString() : p.toStringAsFixed(2))
      : '—';
  return AppStrings.Registration.reviewDeliveryPaid.tr
      .replaceAll('@price', priceStr)
      .replaceAll('@mode', mode);
}

class RegisterReviewScreen extends StatefulWidget {
  const RegisterReviewScreen({super.key});

  @override
  State<RegisterReviewScreen> createState() => _RegisterReviewScreenState();
}

/// The review row a failed sign-up should send the user to, if any.
ReviewField? _fieldForFailure(AuthFailure failure) {
  switch (failure.code) {
    case AuthFailure.outsideServiceArea:
      return ReviewField.location;
    case AuthFailure.phoneAlreadyRegistered:
    case 'invalid-email':
    case 'invalid-phone-number':
      return ReviewField.phone;
  }
  return null;
}

class _RegisterReviewScreenState extends State<RegisterReviewScreen> {
  final _otpRepository = getIt<OtpRepository>();

  /// Section flagged by the last failed submit; cleared once it is edited.
  ReviewField? _errorField;
  String? _errorMessage;

  Future<void> _navigateToPhoneVerification(String phoneE164) async {
    try {
      final result = await _otpRepository.requestOtp(phone: phoneE164);
      if (!mounted) return;
      final ten = egyptTenDigitsFromStored(phoneE164);
      final phoneDisplay = ten != null && ten.length == 10
          ? '+20 ${formatEgyptTenDigitsDisplay(ten)}'
          : phoneE164;
      showOtpSentChannelSnack(
        context,
        channel: result.channel,
        phoneDisplay: phoneDisplay,
      );
      final args = VerifyOtpRouteArgs(
        phone: phoneE164,
        requestToken: result.requestToken,
        flow: VerifyOtpFlow.registerApplication,
      );
      getIt<RegistrationOtpArgsHolder>().stashForRegistration(args);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.verifyOtp, extra: args);
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: otpOrFirebaseError(e),
        state: AppSnackState.error,
        icon: PhosphorIconsRegular.chatCircleDots,
      );
      // OTP send failed — still force verify flow; user can resend from there.
      context.go(AppRoutes.accountVerifyPhone);
    }
  }

  Future<void> _submit() async {
    final draft = context.read<RegistrationCubit>().state;
    final data = draft.toSubmitData();
    if (data == null) {
      AppSnack.show(
        context,
        message: AppStrings.Auth.registrationDataMissing.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
      return;
    }

    final authCubit = context.read<AuthCubit>();
    final failure = await context.withAppLoading(
      () => authCubit.registerProviderInitial(data),
    );

    if (!mounted) return;

    if (failure != null) {
      // Stay on review so the user can fix the flagged section and resubmit.
      final message = failure.message.tr;
      setState(() {
        _errorField = _fieldForFailure(failure);
        _errorMessage = message;
      });
      AppSnack.show(
        context,
        message: message,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
      unawaited(authCubit.dismissFailure());
      return;
    }

    final authState = authCubit.state;

    if (authState is! Authenticated) return;

    // Never skip phone verification after account create.
    final phone = phoneE164FromProfileStored(authState.profile.phone);
    if (phone == null) {
      AppSnack.show(
        context,
        message: AppStrings.Auth.invalidPhone.tr,
        state: AppSnackState.error,
        icon: PhosphorIconsRegular.phoneSlash,
      );
      context.go(AppRoutes.accountVerifyPhone);
      return;
    }

    if (authState.profile.phoneVerified) {
      context.go(AppRoutes.requestSubmitted);
      return;
    }

    await _navigateToPhoneVerification(phone);
  }

  Future<void> _openEdit(ReviewField field) async {
    final before = context.read<RegistrationCubit>().state;
    await showRegisterReviewEditSheet(context, field: field);
    if (!mounted || field != _errorField) return;
    if (context.read<RegistrationCubit>().state != before) {
      setState(() {
        _errorField = null;
        _errorMessage = null;
      });
    }
  }

  List<Widget> _reviewTiles(
    BuildContext context,
    RegistrationDraft draft,
    ColorScheme scheme,
  ) {
    final address = draft.formattedAddress.trim();
    final locationValue = address.isEmpty ? '—' : address;

    final rows =
        <({ReviewField? field, IconData icon, String titleKey, String value})>[
          (
            field: null,
            icon: ToukhIcons.store,
            titleKey: AppStrings.Registration.reviewBusinessType,
            value: draft.kind == null ? '—' : _kindKey(draft.kind!).tr,
          ),
        ];

    final cat = _categoryEntry(draft);
    if (cat != null) {
      rows.add((
        field: null,
        icon: PhosphorIconsRegular.tag,
        titleKey: cat.$1,
        value: cat.$2,
      ));
    }

    if (draft.kind == ServiceType.otherShops) {
      final lang = Get.locale?.languageCode ?? 'ar';
      final label = otherShopChoiceLabel(
        draft.otherShopCategoryId,
        draft.otherShopTypeIds,
        lang,
      );
      rows.addAll([
        (
          field: ReviewField.otherShop,
          icon: PhosphorIconsRegular.tag,
          titleKey: AppStrings.Registration.otherShopReviewTitle,
          value: label.isEmpty ? '—' : label,
        ),
        (
          field: ReviewField.otherShop,
          icon: PhosphorIconsRegular.chatCircleText,
          titleKey: AppStrings.Registration.orderModeReviewTitle,
          value: switch (draft.orderMode) {
            ProviderOrderMode.menu => AppStrings.Registration.orderModeMenu.tr,
            ProviderOrderMode.customRequests =>
              AppStrings.Registration.orderModeCustom.tr,
            null => '—',
          },
        ),
      ]);
    }

    rows.add((
      field: ReviewField.profile,
      icon: PhosphorIconsRegular.identificationBadge,
      titleKey: AppStrings.Registration.brandName,
      value: draft.name.trim().isEmpty ? '—' : draft.name.trim(),
    ));

    if (draft.description.trim().isNotEmpty) {
      rows.add((
        field: ReviewField.profile,
        icon: PhosphorIconsRegular.notepad,
        titleKey: AppStrings.Registration.description,
        value: draft.description.trim(),
      ));
    }

    rows.addAll([
      (
        field: ReviewField.phone,
        icon: ToukhIcons.phone,
        titleKey: AppStrings.Auth.phoneNumber,
        value: draft.phoneNational.trim().isEmpty ? '—' : draft.phoneNational,
      ),
      (
        field: ReviewField.location,
        icon: ToukhIcons.location,
        titleKey: AppStrings.Registration.mapTitle,
        value: locationValue,
      ),
      (
        field: ReviewField.hours,
        icon: ToukhIcons.clock,
        titleKey: AppStrings.Registration.hoursTitle,
        value: _hoursSummary(draft),
      ),
    ]);

    final delivery = _deliverySummary(draft);
    if (delivery != null) {
      rows.add((
        field: ReviewField.delivery,
        icon: ToukhIcons.delivery,
        titleKey: AppStrings.Registration.deliveryTitle,
        value: delivery,
      ));
    }

    final prep = draft.avgPrepMinutes;
    if (prep != null && prep > 0) {
      rows.add((
        field: ReviewField.delivery,
        icon: ToukhIcons.clock,
        titleKey: AppStrings.Registration.reviewPrepTime,
        value: '$prep',
      ));
    }

    final isRestaurant =
        draft.kind == ServiceType.restaurant &&
        draft.shopCategory == ShopCategory.restaurant;
    if (isRestaurant) {
      final labels = draft.cuisineTags
          .map((id) => RestaurantCuisineTaxonomy.byId[id]?.l10nKey.tr)
          .whereType<String>()
          .toList();
      rows.add((
        field: ReviewField.cuisineTags,
        icon: PhosphorIconsRegular.tag,
        titleKey: AppStrings.Registration.cuisineTitle,
        value: labels.isEmpty ? '—' : labels.join(', '),
      ));
    }

    return rows
        .map(
          (r) => RegisterReviewTile(
            icon: r.icon,
            titleKey: r.titleKey,
            value: r.value,
            scheme: scheme,
            errorText: r.field != null && r.field == _errorField
                ? _errorMessage
                : null,
            onTap: r.field != null
                ? () => unawaited(_openEdit(r.field!))
                : null,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;
    final data = draft.toSubmitData();
    final scheme = Theme.of(context).colorScheme;
    return RegistrationStepScaffold(
      stage: RegistrationStage.review,
      icon: PhosphorIconsDuotone.clipboardText,
      title: AppStrings.Registration.reviewTitle,
      subtitle: AppStrings.Registration.reviewSubtitle,
      onNext: () => unawaited(_submit()),
      nextLabelKey: AppStrings.Registration.submit,
      nextEnabled: data != null,
      children: _reviewTiles(context, draft, scheme),
    );
  }
}
