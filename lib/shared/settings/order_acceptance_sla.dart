abstract final class OrderAcceptanceSlaKeys {
  static const restaurants = 'restaurants';
  static const grocery = 'grocery';
  static const pharmacy = 'pharmacy';
  static const homeServices = 'homeServices';
  static const qaima = 'qaima';
  static const defaultKey = 'default';

  static const all = [
    restaurants,
    grocery,
    pharmacy,
    homeServices,
    qaima,
    defaultKey,
  ];
}

/// Configurable per-service-type acceptance SLA in minutes.
class OrderAcceptanceSla {
  const OrderAcceptanceSla({
    this.restaurants = 5,
    this.grocery = 5,
    this.pharmacy = 10,
    this.homeServices = 15,
    this.qaima = 10,
    this.defaultMinutes = 5,
  });

  final int restaurants;
  final int grocery;
  final int pharmacy;
  final int homeServices;
  final int qaima;
  final int defaultMinutes;

  static const defaults = OrderAcceptanceSla();

  int minutesFor(String serviceTypeKey) {
    final key = serviceTypeKey.trim();
    return switch (key) {
      OrderAcceptanceSlaKeys.restaurants => restaurants,
      OrderAcceptanceSlaKeys.grocery => grocery,
      OrderAcceptanceSlaKeys.pharmacy => pharmacy,
      OrderAcceptanceSlaKeys.homeServices => homeServices,
      OrderAcceptanceSlaKeys.qaima => qaima,
      _ => defaultMinutes,
    };
  }

  Map<String, int> get minutesByKey => {
        OrderAcceptanceSlaKeys.restaurants: restaurants,
        OrderAcceptanceSlaKeys.grocery: grocery,
        OrderAcceptanceSlaKeys.pharmacy: pharmacy,
        OrderAcceptanceSlaKeys.homeServices: homeServices,
        OrderAcceptanceSlaKeys.qaima: qaima,
        OrderAcceptanceSlaKeys.defaultKey: defaultMinutes,
      };

  factory OrderAcceptanceSla.fromFirestore(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return defaults;
    int read(String key, int fallback) {
      final v = raw[key];
      if (v is num && v > 0) return v.round();
      return fallback;
    }

    return OrderAcceptanceSla(
      restaurants: read(OrderAcceptanceSlaKeys.restaurants, defaults.restaurants),
      grocery: read(OrderAcceptanceSlaKeys.grocery, defaults.grocery),
      pharmacy: read(OrderAcceptanceSlaKeys.pharmacy, defaults.pharmacy),
      homeServices: read(OrderAcceptanceSlaKeys.homeServices, defaults.homeServices),
      qaima: read(OrderAcceptanceSlaKeys.qaima, defaults.qaima),
      defaultMinutes: read(OrderAcceptanceSlaKeys.defaultKey, defaults.defaultMinutes),
    );
  }

  Map<String, dynamic> toFirestore() => {
        OrderAcceptanceSlaKeys.restaurants: restaurants,
        OrderAcceptanceSlaKeys.grocery: grocery,
        OrderAcceptanceSlaKeys.pharmacy: pharmacy,
        OrderAcceptanceSlaKeys.homeServices: homeServices,
        OrderAcceptanceSlaKeys.qaima: qaima,
        OrderAcceptanceSlaKeys.defaultKey: defaultMinutes,
      };

  OrderAcceptanceSla copyWith({
    int? restaurants,
    int? grocery,
    int? pharmacy,
    int? homeServices,
    int? qaima,
    int? defaultMinutes,
  }) {
    return OrderAcceptanceSla(
      restaurants: restaurants ?? this.restaurants,
      grocery: grocery ?? this.grocery,
      pharmacy: pharmacy ?? this.pharmacy,
      homeServices: homeServices ?? this.homeServices,
      qaima: qaima ?? this.qaima,
      defaultMinutes: defaultMinutes ?? this.defaultMinutes,
    );
  }
}

enum OrderOverdueReason { acceptanceDelay, visitMissed }

/// Maps provider `serviceType` wire values to SLA settings keys.
String slaKeyForProviderServiceType(String? wire) {
  switch (wire?.trim().toLowerCase()) {
    case 'restaurant':
      return OrderAcceptanceSlaKeys.restaurants;
    case 'pharmacy':
      return OrderAcceptanceSlaKeys.pharmacy;
    case 'grocery':
    case 'supermarket':
      return OrderAcceptanceSlaKeys.grocery;
    case 'homeservice':
      return OrderAcceptanceSlaKeys.homeServices;
    case 'qaima':
      return OrderAcceptanceSlaKeys.qaima;
    default:
      return OrderAcceptanceSlaKeys.defaultKey;
  }
}

int acceptanceWarningMinutes(int slaMinutes) {
  final derived = (slaMinutes * 0.4).round();
  return derived < 2 ? 2 : derived;
}

bool isAcceptanceOverdue({
  required Duration elapsed,
  required int slaMinutes,
}) {
  return elapsed > Duration(minutes: slaMinutes);
}

int acceptanceOverdueByMinutes({
  required Duration elapsed,
  required int slaMinutes,
}) {
  final diff = elapsed.inMinutes - slaMinutes;
  return diff < 0 ? 0 : diff;
}
