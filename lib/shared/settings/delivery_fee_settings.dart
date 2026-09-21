import 'package:equatable/equatable.dart';

/// Global courier delivery fee settings (admin-configured).
///
/// Used by Cloud Functions [calculateDeliveryRoute] / fee calculator.
/// Stored under `appSettings/global.deliveryFeeSettings`.
class DeliveryFeeSettings extends Equatable {
  const DeliveryFeeSettings({
    this.pricePerKm = 5,
    this.minimumDeliveryFee = 0,
    this.maximumDeliveryFee = 500,
    this.freeDeliveryThreshold = 0,
    this.distanceRounding = DeliveryDistanceRounding.none,
    this.surgeMultiplier = 1,
    this.nightMultiplier = 1,
    this.rainMultiplier = 1,
    this.rainActive = false,
    this.nightStartHour = 22,
    this.nightEndHour = 6,
    this.settingsVersion = 1,
  });

  static const defaults = DeliveryFeeSettings();

  final double pricePerKm;
  final double minimumDeliveryFee;
  final double maximumDeliveryFee;

  /// Order subtotal (EGP) at/above which delivery is free. `0` disables.
  final double freeDeliveryThreshold;
  final DeliveryDistanceRounding distanceRounding;
  final double surgeMultiplier;
  final double nightMultiplier;
  final double rainMultiplier;
  final bool rainActive;
  final int nightStartHour;
  final int nightEndHour;
  final int settingsVersion;

  factory DeliveryFeeSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    return DeliveryFeeSettings(
      pricePerKm: (data['pricePerKm'] as num?)?.toDouble() ?? 5,
      minimumDeliveryFee: (data['minimumDeliveryFee'] as num?)?.toDouble() ?? 0,
      maximumDeliveryFee:
          (data['maximumDeliveryFee'] as num?)?.toDouble() ?? 500,
      freeDeliveryThreshold:
          (data['freeDeliveryThreshold'] as num?)?.toDouble() ?? 0,
      distanceRounding:
          DeliveryDistanceRounding.fromWire(data['distanceRounding'] as String?),
      surgeMultiplier: (data['surgeMultiplier'] as num?)?.toDouble() ?? 1,
      nightMultiplier: (data['nightMultiplier'] as num?)?.toDouble() ?? 1,
      rainMultiplier: (data['rainMultiplier'] as num?)?.toDouble() ?? 1,
      rainActive: data['rainActive'] as bool? ?? false,
      nightStartHour: (data['nightStartHour'] as num?)?.toInt() ?? 22,
      nightEndHour: (data['nightEndHour'] as num?)?.toInt() ?? 6,
      settingsVersion: (data['settingsVersion'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'pricePerKm': pricePerKm,
        'minimumDeliveryFee': minimumDeliveryFee,
        'maximumDeliveryFee': maximumDeliveryFee,
        'freeDeliveryThreshold': freeDeliveryThreshold,
        'distanceRounding': distanceRounding.wireValue,
        'surgeMultiplier': surgeMultiplier,
        'nightMultiplier': nightMultiplier,
        'rainMultiplier': rainMultiplier,
        'rainActive': rainActive,
        'nightStartHour': nightStartHour,
        'nightEndHour': nightEndHour,
        'settingsVersion': settingsVersion,
      };

  DeliveryFeeSettings copyWith({
    double? pricePerKm,
    double? minimumDeliveryFee,
    double? maximumDeliveryFee,
    double? freeDeliveryThreshold,
    DeliveryDistanceRounding? distanceRounding,
    double? surgeMultiplier,
    double? nightMultiplier,
    double? rainMultiplier,
    bool? rainActive,
    int? nightStartHour,
    int? nightEndHour,
    int? settingsVersion,
  }) {
    return DeliveryFeeSettings(
      pricePerKm: pricePerKm ?? this.pricePerKm,
      minimumDeliveryFee: minimumDeliveryFee ?? this.minimumDeliveryFee,
      maximumDeliveryFee: maximumDeliveryFee ?? this.maximumDeliveryFee,
      freeDeliveryThreshold:
          freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      distanceRounding: distanceRounding ?? this.distanceRounding,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      nightMultiplier: nightMultiplier ?? this.nightMultiplier,
      rainMultiplier: rainMultiplier ?? this.rainMultiplier,
      rainActive: rainActive ?? this.rainActive,
      nightStartHour: nightStartHour ?? this.nightStartHour,
      nightEndHour: nightEndHour ?? this.nightEndHour,
      settingsVersion: settingsVersion ?? this.settingsVersion,
    );
  }

  @override
  List<Object?> get props => [
        pricePerKm,
        minimumDeliveryFee,
        maximumDeliveryFee,
        freeDeliveryThreshold,
        distanceRounding,
        surgeMultiplier,
        nightMultiplier,
        rainMultiplier,
        rainActive,
        nightStartHour,
        nightEndHour,
        settingsVersion,
      ];
}

enum DeliveryDistanceRounding {
  none,
  ceil100m,
  roundKm;

  String get wireValue => switch (this) {
        DeliveryDistanceRounding.none => 'none',
        DeliveryDistanceRounding.ceil100m => 'ceil100m',
        DeliveryDistanceRounding.roundKm => 'roundKm',
      };

  static DeliveryDistanceRounding fromWire(String? raw) {
    switch (raw?.trim()) {
      case 'ceil100m':
        return DeliveryDistanceRounding.ceil100m;
      case 'roundKm':
        return DeliveryDistanceRounding.roundKm;
      default:
        return DeliveryDistanceRounding.none;
    }
  }
}
