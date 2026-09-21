import 'package:equatable/equatable.dart';

/// How a store-delivery provider prices its own delivery.
enum StoreDeliveryPricingMode {
  fixed,
  perKm;

  static StoreDeliveryPricingMode fromWire(String? raw) {
    if (raw == 'perKm') return StoreDeliveryPricingMode.perKm;
    return StoreDeliveryPricingMode.fixed;
  }

  String get wireValue => name;
}

/// Provider delivery pricing used by [DeliveryFeeCalculator].
class ProviderDeliveryConfig extends Equatable {
  const ProviderDeliveryConfig({
    required this.providerId,
    this.offersDelivery = false,
    this.deliveryFeeEgp = 0,
    this.freeDelivery = false,
    this.pricingMode = StoreDeliveryPricingMode.fixed,
    this.storeLat,
    this.storeLng,
  });

  final String providerId;

  /// When true, the store fulfills delivery (not Toukh courier).
  final bool offersDelivery;

  /// Fixed fee EGP, or EGP per km when [pricingMode] is [StoreDeliveryPricingMode.perKm].
  final double deliveryFeeEgp;

  final bool freeDelivery;
  final StoreDeliveryPricingMode pricingMode;

  /// Store coordinates for per-km fees (from provider doc).
  final double? storeLat;
  final double? storeLng;

  bool get hasStoreCoords =>
      storeLat != null &&
      storeLng != null &&
      !(storeLat == 0 && storeLng == 0);

  factory ProviderDeliveryConfig.fromMap(
    String providerId,
    Map<String, dynamic>? map,
  ) {
    if (map == null) {
      return ProviderDeliveryConfig(providerId: providerId);
    }
    final delivery = map['deliveryConfig'];
    final cfg = delivery is Map ? Map<String, dynamic>.from(delivery) : map;

    final price = (cfg['priceEgp'] as num?)?.toDouble() ??
        (cfg['deliveryFeeEgp'] as num?)?.toDouble() ??
        (cfg['fixedDeliveryFee'] as num?)?.toDouble() ??
        0;

    final lat = (map['lat'] as num?)?.toDouble() ??
        (map['location'] is Map
            ? (map['location']['lat'] as num?)?.toDouble()
            : null) ??
        (map['geo'] is Map ? (map['geo']['lat'] as num?)?.toDouble() : null);
    final lng = (map['lng'] as num?)?.toDouble() ??
        (map['location'] is Map
            ? (map['location']['lng'] as num?)?.toDouble()
            : null) ??
        (map['geo'] is Map ? (map['geo']['lng'] as num?)?.toDouble() : null);

    return ProviderDeliveryConfig(
      providerId: providerId,
      offersDelivery: _truthy(cfg['offersDelivery']),
      deliveryFeeEgp: price,
      freeDelivery: _truthy(cfg['freeDelivery']) || _truthy(cfg['isFree']),
      pricingMode: StoreDeliveryPricingMode.fromWire(
        cfg['pricingMode'] as String?,
      ),
      storeLat: lat,
      storeLng: lng,
    );
  }

  /// Accepts bool, 1/0, and common string wire values.
  static bool _truthy(dynamic value) {
    if (value == true || value == 1) return true;
    if (value is String) {
      final v = value.trim().toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  ProviderDeliveryConfig copyWith({
    bool? offersDelivery,
    double? deliveryFeeEgp,
    bool? freeDelivery,
    StoreDeliveryPricingMode? pricingMode,
    double? storeLat,
    double? storeLng,
  }) {
    return ProviderDeliveryConfig(
      providerId: providerId,
      offersDelivery: offersDelivery ?? this.offersDelivery,
      deliveryFeeEgp: deliveryFeeEgp ?? this.deliveryFeeEgp,
      freeDelivery: freeDelivery ?? this.freeDelivery,
      pricingMode: pricingMode ?? this.pricingMode,
      storeLat: storeLat ?? this.storeLat,
      storeLng: storeLng ?? this.storeLng,
    );
  }

  @override
  List<Object?> get props => [
        providerId,
        offersDelivery,
        deliveryFeeEgp,
        freeDelivery,
        pricingMode,
        storeLat,
        storeLng,
      ];
}
