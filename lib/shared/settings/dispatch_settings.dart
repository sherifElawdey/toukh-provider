import 'package:equatable/equatable.dart';

/// Global dispatch / ride matching settings (admin-configured).
///
/// Stored under `appSettings/global.dispatchSettings`.
class DispatchSettings extends Equatable {
  const DispatchSettings({
    this.driverSearchRadiusKm = 2,
    this.pickupArrivalMeters = 100,
    this.destinationArrivalMeters = 100,
    this.pricePerKm = 5,
    this.minimumTripPrice = 0,
    this.maximumTripPrice = 500,
    this.penaltyPercent = 10,
    this.waitingTimeoutSec = 120,
    this.driverOfferTimeoutSec = 60,
    this.realtimeUpdateIntervalSec = 5,
    this.surgeMultiplier = 1,
    this.nightMultiplier = 1,
    this.rainMultiplier = 1,
    this.holidayMultiplier = 1,
    this.rainActive = false,
    this.holidayActive = false,
    this.nightStartHour = 22,
    this.nightEndHour = 6,
    this.navigationProvider = 'google',
    this.settingsVersion = 1,
  });

  static const defaults = DispatchSettings();

  final double driverSearchRadiusKm;
  final int pickupArrivalMeters;
  final int destinationArrivalMeters;
  final double pricePerKm;
  final double minimumTripPrice;
  final double maximumTripPrice;
  final double penaltyPercent;
  final int waitingTimeoutSec;
  final int driverOfferTimeoutSec;
  final int realtimeUpdateIntervalSec;
  final double surgeMultiplier;
  final double nightMultiplier;
  final double rainMultiplier;
  final double holidayMultiplier;
  final bool rainActive;
  final bool holidayActive;
  final int nightStartHour;
  final int nightEndHour;
  final String navigationProvider;
  final int settingsVersion;

  int get driverSearchRadiusMeters =>
      (driverSearchRadiusKm * 1000).round().clamp(100, 50000);

  factory DispatchSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    return DispatchSettings(
      driverSearchRadiusKm:
          (data['driverSearchRadiusKm'] as num?)?.toDouble() ?? 2,
      pickupArrivalMeters:
          (data['pickupArrivalMeters'] as num?)?.toInt() ?? 100,
      destinationArrivalMeters:
          (data['destinationArrivalMeters'] as num?)?.toInt() ?? 100,
      pricePerKm: (data['pricePerKm'] as num?)?.toDouble() ?? 5,
      minimumTripPrice: (data['minimumTripPrice'] as num?)?.toDouble() ?? 0,
      maximumTripPrice: (data['maximumTripPrice'] as num?)?.toDouble() ?? 500,
      penaltyPercent: (data['penaltyPercent'] as num?)?.toDouble() ?? 10,
      waitingTimeoutSec: (data['waitingTimeoutSec'] as num?)?.toInt() ?? 120,
      driverOfferTimeoutSec:
          (data['driverOfferTimeoutSec'] as num?)?.toInt() ?? 60,
      realtimeUpdateIntervalSec:
          (data['realtimeUpdateIntervalSec'] as num?)?.toInt() ?? 5,
      surgeMultiplier: (data['surgeMultiplier'] as num?)?.toDouble() ?? 1,
      nightMultiplier: (data['nightMultiplier'] as num?)?.toDouble() ?? 1,
      rainMultiplier: (data['rainMultiplier'] as num?)?.toDouble() ?? 1,
      holidayMultiplier: (data['holidayMultiplier'] as num?)?.toDouble() ?? 1,
      rainActive: data['rainActive'] as bool? ?? false,
      holidayActive: data['holidayActive'] as bool? ?? false,
      nightStartHour: (data['nightStartHour'] as num?)?.toInt() ?? 22,
      nightEndHour: (data['nightEndHour'] as num?)?.toInt() ?? 6,
      navigationProvider: data['navigationProvider'] as String? ?? 'google',
      settingsVersion: (data['settingsVersion'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'driverSearchRadiusKm': driverSearchRadiusKm,
        'pickupArrivalMeters': pickupArrivalMeters,
        'destinationArrivalMeters': destinationArrivalMeters,
        'pricePerKm': pricePerKm,
        'minimumTripPrice': minimumTripPrice,
        'maximumTripPrice': maximumTripPrice,
        'penaltyPercent': penaltyPercent,
        'waitingTimeoutSec': waitingTimeoutSec,
        'driverOfferTimeoutSec': driverOfferTimeoutSec,
        'realtimeUpdateIntervalSec': realtimeUpdateIntervalSec,
        'surgeMultiplier': surgeMultiplier,
        'nightMultiplier': nightMultiplier,
        'rainMultiplier': rainMultiplier,
        'holidayMultiplier': holidayMultiplier,
        'rainActive': rainActive,
        'holidayActive': holidayActive,
        'nightStartHour': nightStartHour,
        'nightEndHour': nightEndHour,
        'navigationProvider': navigationProvider,
        'settingsVersion': settingsVersion,
      };

  DispatchSettings copyWith({
    double? driverSearchRadiusKm,
    int? pickupArrivalMeters,
    int? destinationArrivalMeters,
    double? pricePerKm,
    double? minimumTripPrice,
    double? maximumTripPrice,
    double? penaltyPercent,
    int? waitingTimeoutSec,
    int? driverOfferTimeoutSec,
    int? realtimeUpdateIntervalSec,
    double? surgeMultiplier,
    double? nightMultiplier,
    double? rainMultiplier,
    double? holidayMultiplier,
    bool? rainActive,
    bool? holidayActive,
    int? nightStartHour,
    int? nightEndHour,
    String? navigationProvider,
    int? settingsVersion,
  }) {
    return DispatchSettings(
      driverSearchRadiusKm: driverSearchRadiusKm ?? this.driverSearchRadiusKm,
      pickupArrivalMeters: pickupArrivalMeters ?? this.pickupArrivalMeters,
      destinationArrivalMeters:
          destinationArrivalMeters ?? this.destinationArrivalMeters,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      minimumTripPrice: minimumTripPrice ?? this.minimumTripPrice,
      maximumTripPrice: maximumTripPrice ?? this.maximumTripPrice,
      penaltyPercent: penaltyPercent ?? this.penaltyPercent,
      waitingTimeoutSec: waitingTimeoutSec ?? this.waitingTimeoutSec,
      driverOfferTimeoutSec:
          driverOfferTimeoutSec ?? this.driverOfferTimeoutSec,
      realtimeUpdateIntervalSec:
          realtimeUpdateIntervalSec ?? this.realtimeUpdateIntervalSec,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      nightMultiplier: nightMultiplier ?? this.nightMultiplier,
      rainMultiplier: rainMultiplier ?? this.rainMultiplier,
      holidayMultiplier: holidayMultiplier ?? this.holidayMultiplier,
      rainActive: rainActive ?? this.rainActive,
      holidayActive: holidayActive ?? this.holidayActive,
      nightStartHour: nightStartHour ?? this.nightStartHour,
      nightEndHour: nightEndHour ?? this.nightEndHour,
      navigationProvider: navigationProvider ?? this.navigationProvider,
      settingsVersion: settingsVersion ?? this.settingsVersion,
    );
  }

  @override
  List<Object?> get props => [
        driverSearchRadiusKm,
        pickupArrivalMeters,
        destinationArrivalMeters,
        pricePerKm,
        minimumTripPrice,
        maximumTripPrice,
        penaltyPercent,
        waitingTimeoutSec,
        driverOfferTimeoutSec,
        realtimeUpdateIntervalSec,
        surgeMultiplier,
        nightMultiplier,
        rainMultiplier,
        holidayMultiplier,
        rainActive,
        holidayActive,
        nightStartHour,
        nightEndHour,
        navigationProvider,
        settingsVersion,
      ];
}
