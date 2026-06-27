import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/features/registration/models/registration_submit_data.dart';
import 'package:toukh_provider/features/settings/domain/provider_profile_draft_mapper.dart';

ShopCategory? shopCategoryForSubmit(ServiceType kind, ShopCategory? draft) {
  switch (kind) {
    case ServiceType.restaurant:
      return draft;
    case ServiceType.supermarket:
      return ShopCategory.supermarket;
    case ServiceType.pharmacy:
      return ShopCategory.pharmacy;
    case ServiceType.grocery:
      return ShopCategory.fruitVeg;
    case ServiceType.homeService:
    case ServiceType.homeBrands:
      return null;
  }
}

class RegistrationDraft extends Equatable {
  const RegistrationDraft({
    this.kind,
    this.shopCategory,
    this.serviceCategoryId,
    this.phoneNational = '',
    this.password = '',
    this.idFront,
    this.idBack,
    this.brandImage,
    this.name = '',
    this.description = '',
    this.lat,
    this.lng,
    this.formattedAddress = '',
    this.city,
    this.workingHours = const {},
    this.deliveryConfig,
    this.avgPrepMinutes,
  });

  final ServiceType? kind;
  final ShopCategory? shopCategory;
  final String? serviceCategoryId;

  final String phoneNational;
  final String password;

  final File? idFront;
  final File? idBack;
  final File? brandImage;

  final String name;
  final String description;

  final double? lat;
  final double? lng;
  final String formattedAddress;
  final String? city;

  final Map<Weekday, DaySchedule> workingHours;
  final DeliveryConfig? deliveryConfig;
  final int? avgPrepMinutes;

  RegistrationDraft copyWith({
    ServiceType? kind,
    ShopCategory? shopCategory,
    bool clearShopCategory = false,
    String? serviceCategoryId,
    bool clearServiceCategoryId = false,
    String? phoneNational,
    String? password,
    File? idFront,
    File? idBack,
    File? brandImage,
    String? name,
    String? description,
    double? lat,
    double? lng,
    String? formattedAddress,
    String? city,
    bool clearCity = false,
    Map<Weekday, DaySchedule>? workingHours,
    DeliveryConfig? deliveryConfig,
    int? avgPrepMinutes,
  }) {
    return RegistrationDraft(
      kind: kind ?? this.kind,
      shopCategory:
          clearShopCategory ? null : (shopCategory ?? this.shopCategory),
      serviceCategoryId: clearServiceCategoryId
          ? null
          : (serviceCategoryId ?? this.serviceCategoryId),
      phoneNational: phoneNational ?? this.phoneNational,
      password: password ?? this.password,
      idFront: idFront ?? this.idFront,
      idBack: idBack ?? this.idBack,
      brandImage: brandImage ?? this.brandImage,
      name: name ?? this.name,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      city: clearCity ? null : (city ?? this.city),
      workingHours: workingHours ?? this.workingHours,
      deliveryConfig: deliveryConfig ?? this.deliveryConfig,
      avgPrepMinutes: avgPrepMinutes ?? this.avgPrepMinutes,
    );
  }

  bool get canProceedCategory {
    final k = kind;
    if (k == null) return false;
    if (k == ServiceType.restaurant) return shopCategory != null;
    if (k == ServiceType.homeService) {
      return serviceCategoryId != null && serviceCategoryId!.isNotEmpty;
    }
    return true;
  }

  RegistrationSubmitData? toSubmitData() {
    final k = kind;
    if (k == null) return null;
    if (idFront == null || idBack == null || brandImage == null) return null;
    if (lat == null || lng == null) return null;
    if (name.trim().isEmpty) return null;
    final raw = phoneNational.replaceAll(RegExp(r'\D'), '');
    final ten =
        raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
    if (ten.length != 10) return null;
    final phone = egyptMobileE164(ten);
    if (phone.isEmpty) return null;
    if (password.length < 6) return null;
    if (!canProceedCategory) return null;

    return RegistrationSubmitData(
      phone: phone,
      password: password,
      kind: k,
      shopCategory: shopCategoryForSubmit(k, shopCategory),
      serviceCategoryId: k == ServiceType.homeService ? serviceCategoryId : null,
      idFront: idFront!,
      idBack: idBack!,
      brandImage: brandImage!,
      name: name.trim(),
      description: description.trim(),
      lat: lat!,
      lng: lng!,
      formattedAddress: formattedAddress.trim(),
      city: city,
      workingHours: workingHours,
      deliveryConfig: deliveryConfig,
      avgPrepMinutes: avgPrepMinutes,
    );
  }

  @override
  List<Object?> get props => [
        kind,
        shopCategory,
        serviceCategoryId,
        phoneNational,
        password,
        idFront?.path,
        idBack?.path,
        brandImage?.path,
        name,
        description,
        lat,
        lng,
        formattedAddress,
        city,
        workingHours,
        deliveryConfig,
        avgPrepMinutes,
      ];
}

class RegistrationCubit extends Cubit<RegistrationDraft> {
  RegistrationCubit() : super(_initial());

  static RegistrationDraft _initial() {
    final wh = <Weekday, DaySchedule>{};
    for (final d in Weekday.all) {
      wh[d] = const DaySchedule(
        enabled: false,
        twentyFourHours: false,
        openFromMinutes: 9 * 60,
        openToMinutes: 22 * 60,
      );
    }
    return RegistrationDraft(workingHours: wh);
  }

  /// Sets [kind] and category fields appropriate for the next registration step.
  void selectKindForRegistration(ServiceType kind) {
    switch (kind) {
      case ServiceType.restaurant:
        emit(state.copyWith(
          kind: kind,
          shopCategory: ShopCategory.restaurant,
          clearServiceCategoryId: true,
        ));
      case ServiceType.homeService:
        emit(state.copyWith(
          kind: kind,
          clearShopCategory: true,
          clearServiceCategoryId: true,
        ));
      case ServiceType.supermarket:
        emit(state.copyWith(
          kind: kind,
          shopCategory: ShopCategory.supermarket,
          clearServiceCategoryId: true,
        ));
      case ServiceType.pharmacy:
        emit(state.copyWith(
          kind: kind,
          shopCategory: ShopCategory.pharmacy,
          clearServiceCategoryId: true,
        ));
      case ServiceType.grocery:
        emit(state.copyWith(
          kind: kind,
          shopCategory: ShopCategory.fruitVeg,
          clearServiceCategoryId: true,
        ));
      case ServiceType.homeBrands:
        emit(state.copyWith(
          kind: kind,
          clearShopCategory: true,
          clearServiceCategoryId: true,
        ));
    }
  }

  void setShopCategory(ShopCategory c) => emit(state.copyWith(
        shopCategory: c,
        clearServiceCategoryId: true,
      ));

  void setServiceCategoryId(String id) => emit(state.copyWith(
        serviceCategoryId: id,
        clearShopCategory: true,
      ));

  void setCredentials({
    required String phoneNational,
    required String password,
    required File idFront,
    required File idBack,
    required File brandImage,
  }) {
    emit(state.copyWith(
      phoneNational: phoneNational,
      password: password,
      idFront: idFront,
      idBack: idBack,
      brandImage: brandImage,
    ));
  }

  void setPhoneNational(String phoneNational) =>
      emit(state.copyWith(phoneNational: phoneNational));

  void setProfile({
    required String name,
    required String description,
  }) {
    emit(state.copyWith(
      name: name,
      description: description,
    ));
  }

  void setLocation({
    required double lat,
    required double lng,
    required String formattedAddress,
    String? city,
  }) {
    emit(state.copyWith(
      lat: lat,
      lng: lng,
      formattedAddress: formattedAddress,
      city: city,
      clearCity: city == null,
    ));
  }

  void setWorkingHours(Map<Weekday, DaySchedule> wh) =>
      emit(state.copyWith(workingHours: wh));

  void setDelivery({
    DeliveryConfig? deliveryConfig,
    int? avgPrepMinutes,
  }) {
    emit(state.copyWith(
      deliveryConfig: deliveryConfig,
      avgPrepMinutes: avgPrepMinutes,
    ));
  }

  void reset() => emit(_initial());

  /// Seeds draft fields from a live provider profile (account details editing).
  void seedFromProfile(ProviderProfile profile) {
    emit(ProviderProfileDraftMapper.draftFromProfile(profile));
  }
}
