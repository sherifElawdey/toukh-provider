import 'dart:io';

import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';

/// Full payload collected before account creation (review step).
class RegistrationSubmitData {
  const RegistrationSubmitData({
    required this.phone,
    required this.password,
    required this.kind,
    this.shopCategory,
    this.serviceCategoryId,
    required this.idFront,
    required this.idBack,
    required this.brandImage,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    this.city,
    required this.workingHours,
    this.deliveryConfig,
    this.avgPrepMinutes,
  });

  final String phone;
  final String password;
  final ServiceType kind;
  final ShopCategory? shopCategory;
  final String? serviceCategoryId;

  final File idFront;
  final File idBack;
  final File brandImage;

  final String name;
  final String description;

  final double lat;
  final double lng;
  final String formattedAddress;
  final String? city;

  final Map<Weekday, DaySchedule> workingHours;
  final DeliveryConfig? deliveryConfig;
  final int? avgPrepMinutes;
}
