import 'package:toukh_provider/core/utils/phone_e164.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/review_field.dart';

/// Maps between live [ProviderProfile] and [RegistrationDraft] for account editing.
abstract final class ProviderProfileDraftMapper {
  ProviderProfileDraftMapper._();

  static RegistrationDraft draftFromProfile(ProviderProfile profile) {
    final wh = Map<Weekday, DaySchedule>.from(profile.workingHours);
    if (wh.isEmpty) {
      for (final day in Weekday.all) {
        wh[day] = const DaySchedule(
          enabled: false,
          twentyFourHours: false,
          openFromMinutes: 9 * 60,
          openToMinutes: 22 * 60,
        );
      }
    }

    final phoneNational = egyptTenDigitsFromStored(profile.phone) ?? '';

    return RegistrationDraft(
      kind: profile.serviceType,
      shopCategory: profile.shopCategory,
      serviceCategoryId: profile.serviceCategoryId,
      phoneNational: phoneNational,
      password: profile.password,
      name: profile.name,
      description: profile.description ?? '',
      lat: profile.lat,
      lng: profile.lng,
      formattedAddress: profile.address ?? '',
      city: profile.city,
      workingHours: wh,
      deliveryConfig: profile.deliveryConfig,
      avgPrepMinutes: profile.avgPrepMinutes,
    );
  }

  static ProviderProfile applyDraft(
    ProviderProfile base,
    RegistrationDraft draft,
    ReviewField field,
  ) {
    final now = DateTime.now();
    switch (field) {
      case ReviewField.profile:
        return base.copyWith(
          name: draft.name.trim(),
          description: draft.description.trim().isEmpty
              ? null
              : draft.description.trim(),
          updatedAt: now,
        );
      case ReviewField.location:
        return base.copyWith(
          lat: draft.lat,
          lng: draft.lng,
          address: draft.formattedAddress.trim().isEmpty
              ? null
              : draft.formattedAddress.trim(),
          city: draft.city,
          updatedAt: now,
        );
      case ReviewField.hours:
        return base.copyWith(
          workingHours: draft.workingHours,
          updatedAt: now,
        );
      case ReviewField.delivery:
        return base.copyWith(
          deliveryConfig: draft.deliveryConfig,
          avgPrepMinutes: draft.avgPrepMinutes,
          updatedAt: now,
        );
      case ReviewField.kind:
      case ReviewField.category:
      case ReviewField.phone:
        return base;
    }
  }
}
