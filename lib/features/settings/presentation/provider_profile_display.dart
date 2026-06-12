import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

String providerKindLabelKey(ServiceType kind) {
  switch (kind) {
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

String shopCategoryLabel(ShopCategory category) {
  switch (category) {
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

(String titleKey, String value)? categoryEntryFromDraft(RegistrationDraft draft) {
  final kind = draft.kind;
  if (kind == ServiceType.homeService &&
      draft.serviceCategoryId != null &&
      draft.serviceCategoryId!.trim().isNotEmpty) {
    return (
      AppStrings.Registration.serviceCategoryTitle,
      draft.serviceCategoryId!.trim(),
    );
  }
  final shopCategory = draft.shopCategory;
  if (shopCategory != null &&
      (kind == ServiceType.restaurant ||
          kind == ServiceType.supermarket ||
          kind == ServiceType.pharmacy ||
          kind == ServiceType.grocery)) {
    return (
      AppStrings.Registration.shopCategoryTitle,
      shopCategoryLabel(shopCategory),
    );
  }
  return null;
}

String hoursSummaryFromDraft(RegistrationDraft draft) {
  final wh = draft.workingHours;
  var openDays = 0;
  DaySchedule? sample;
  for (final day in Weekday.all) {
    final schedule = wh[day]!;
    if (schedule.enabled) {
      openDays++;
      sample ??= schedule;
    }
  }
  if (openDays == 0) return '—';
  final s = sample!;
  if (s.twentyFourHours) {
    return '${AppStrings.Registration.hoursOpen24h.tr} · $openDays';
  }
  final from = s.openFromMinutes ?? 0;
  final to = s.openToMinutes ?? 0;
  String fmt(int minutes) {
    final hh = minutes ~/ 60;
    final mm = minutes % 60;
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }
  return '$openDays · ${fmt(from)}–${fmt(to)}';
}

String? deliverySummaryFromDraft(RegistrationDraft draft) {
  if (draft.kind == ServiceType.homeService) return null;
  final config = draft.deliveryConfig;
  if (config == null) return AppStrings.Registration.reviewDeliveryNotSet.tr;
  if (!config.offersDelivery) {
    return AppStrings.Registration.reviewDeliveryNone.tr;
  }
  if (config.isFree) return AppStrings.Registration.reviewDeliveryFree.tr;
  final price = config.priceEgp;
  final mode = config.pricingMode == DeliveryPricingMode.perKm
      ? AppStrings.Registration.deliveryModePerKm.tr
      : AppStrings.Registration.deliveryModeFixed.tr;
  final priceStr = price != null && price > 0
      ? (price == price.roundToDouble()
          ? price.toInt().toString()
          : price.toStringAsFixed(2))
      : '—';
  return AppStrings.Registration.reviewDeliveryPaid.tr
      .replaceAll('@price', priceStr)
      .replaceAll('@mode', mode);
}

String formatProviderPhone(String phone) {
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return '—';
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11 && digits.startsWith('0')) {
    return '+20 ${digits.substring(1)}';
  }
  if (digits.length == 10) {
    return '+20 $digits';
  }
  return trimmed;
}

String formatMemberSince(DateTime createdAt, String locale) {
  return DateFormat.yMMMMd(locale).format(createdAt);
}

String accountStatusLabelKey(ProviderAccountStatus status) {
  switch (status) {
    case ProviderAccountStatus.active:
      return AppStrings.Settings.statusActive;
    case ProviderAccountStatus.pending:
      return AppStrings.Settings.statusPending;
    case ProviderAccountStatus.unverified:
      return AppStrings.Settings.statusUnverified;
    case ProviderAccountStatus.blocked:
      return AppStrings.Settings.statusBlocked;
    case ProviderAccountStatus.deleted:
      return AppStrings.Settings.statusDeleted;
  }
}

String serviceTypeSubtitle(ProviderProfile profile) {
  final type = profile.serviceType;
  if (type == ServiceType.restaurant && profile.shopCategory != null) {
    return shopCategoryLabel(profile.shopCategory!);
  }
  if (type == ServiceType.homeService && profile.serviceCategoryId != null) {
    return profile.serviceCategoryId!;
  }
  return providerKindLabelKey(type).tr;
}
