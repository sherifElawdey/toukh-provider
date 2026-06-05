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
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/auth/presentation/otp_delivery_snack.dart';
import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';
import 'package:toukh_provider/features/auth/registration_otp_args_holder.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/register_review_edit_sheet.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/register_review_tile.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
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
    return (
      AppStrings.Registration.serviceCategoryTitle,
      d.serviceCategoryId!.trim(),
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
  final wh = d.workingHours;
  var openDays = 0;
  DaySchedule? sample;
  for (final day in Weekday.all) {
    final s = wh[day]!;
    if (s.enabled) {
      openDays++;
      sample ??= s;
    }
  }
  if (openDays == 0) return '—';
  final s = sample!;
  if (s.twentyFourHours) {
    return '${AppStrings.Registration.hoursOpen24h.tr} · $openDays';
  }
  final from = s.openFromMinutes ?? 0;
  final to = s.openToMinutes ?? 0;
  String fmt(int m) {
    final hh = m ~/ 60;
    final mm = m % 60;
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }
  return '$openDays · ${fmt(from)}–${fmt(to)}';
}

String? _deliverySummary(RegistrationDraft d) {
  if (d.kind == ServiceType.homeService) return null;
  final c = d.deliveryConfig;
  if (c == null) return AppStrings.Registration.reviewDeliveryNotSet.tr;
  if (!c.offersDelivery) {
    return AppStrings.Registration.reviewDeliveryNone.tr;
  }
  if (c.isFree) return AppStrings.Registration.reviewDeliveryFree.tr;
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

class _RegisterReviewScreenState extends State<RegisterReviewScreen> {
  final _otpRepository = getIt<OtpRepository>();

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
      if (mounted) {
        AppSnack.show(
          context,
          message: messageForOtpError(e),
          state: AppSnackState.error,
          icon: PhosphorIconsRegular.chatCircleDots,
        );
      }
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
    await context.withAppLoading(() async {
      await authCubit.registerProviderInitial(data);
    });

    if (!mounted) return;

    final authState = authCubit.state;
    if (authState is AuthFailure) {
      AppSnack.show(
        context,
        message: authState.message,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
      authCubit.dismissFailure();
      return;
    }

    if (authState is! Authenticated) return;

    if (authState.profile.phoneVerified) {
      context.go(AppRoutes.requestSubmitted);
      return;
    }

    final phone = phoneE164FromProfileStored(authState.profile.phone);
    if (phone == null) {
      AppSnack.show(
        context,
        message: AppStrings.Auth.invalidPhone.tr,
        state: AppSnackState.error,
        icon: PhosphorIconsRegular.phoneSlash,
      );
      return;
    }

    await _navigateToPhoneVerification(phone);
  }

  void _openEdit(BuildContext context, ReviewField field) {
    unawaited(showRegisterReviewEditSheet(context, field: field));
  }

  List<Widget> _reviewTiles(
    BuildContext context,
    RegistrationDraft draft,
    ColorScheme scheme,
  ) {
    final address = draft.formattedAddress.trim();
    final locationValue = address.isEmpty ? '—' : address;

    final rows = <({ReviewField? field, IconData icon, String titleKey, String value})>[
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

    return rows
        .map(
          (r) => RegisterReviewTile(
            icon: r.icon,
            titleKey: r.titleKey,
            value: r.value,
            scheme: scheme,
            onTap: r.field != null ? () => _openEdit(context, r.field!) : null,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;
    final data = draft.toSubmitData();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(ToukhIcons.back),
            onPressed: () => context.pop(),
          ),
          title: CustomText(AppStrings.Registration.reviewTitle),
        ),
        body: Padding(
          padding: AppSizes.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                AppStrings.Registration.reviewTapToEdit.tr,
                style: TextStyle(
                  fontSize: AppSizes.fontCaption,
                  color: scheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
              SizedBox(height: AppSizes.spaceMd),
              Expanded(
                child: ListView(
                  children: _reviewTiles(context, draft, scheme),
                ),
              ),
              RegistrationStepNavFooter(
                onBack: () => context.pop(),
                onNext: () => unawaited(_submit()),
                nextLabelKey: AppStrings.Registration.submit,
                nextEnabled: data != null,
              ),
            ],
          ),
        ),
    );
  }
}

