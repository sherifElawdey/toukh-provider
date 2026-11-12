import 'package:equatable/equatable.dart';
import 'package:toukh_ui/toukh_ui.dart' show kStoreCityRadiusKm;

enum DeliveryPricingMode {
  /// Legacy: a fee the store typed in. Read only; new configs use [app].
  fixed,

  /// Legacy: store's own rate per km. Read only.
  perKm,

  /// Legacy: one fee within the city (under [kStoreCityRadiusKm]), another
  /// outside. Read only.
  byRegion,

  /// Fee comes from Havit's delivery pricing (admin settings), the same as
  /// a Havit courier order. Stores never type in their own fee.
  app;

  String get wireValue => name;

  static DeliveryPricingMode? tryParse(String? raw) {
    if (raw == null) return null;
    for (final v in DeliveryPricingMode.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

class DeliveryConfig extends Equatable {
  const DeliveryConfig({
    required this.offersDelivery,
    required this.isFree,
    this.manageFromAccount = false,
    this.pricingMode,
    this.priceEgp,
    this.innerCityFeeEgp,
    this.outerCityFeeEgp,
    this.avgPrepMinutes,
  });

  final bool offersDelivery;
  final bool isFree;

  /// Paid store delivery priced by Havit ([DeliveryPricingMode.app]).
  bool get usesAppPricing =>
      offersDelivery && !isFree && pricingMode == DeliveryPricingMode.app;

  /// Provider delivers the order from this account. No driver is requested.
  final bool manageFromAccount;
  final DeliveryPricingMode? pricingMode;
  final double? priceEgp;

  /// [DeliveryPricingMode.byRegion] fees.
  final double? innerCityFeeEgp;
  final double? outerCityFeeEgp;
  final int? avgPrepMinutes;

  Map<String, dynamic> toFirestore() => {
        'offersDelivery': offersDelivery,
        'isFree': isFree,
        'manageFromAccount': manageFromAccount,
        if (pricingMode != null) 'pricingMode': pricingMode!.wireValue,
        if (priceEgp != null) 'priceEgp': priceEgp,
        if (innerCityFeeEgp != null) 'innerCityFeeEgp': innerCityFeeEgp,
        if (outerCityFeeEgp != null) 'outerCityFeeEgp': outerCityFeeEgp,
        if (avgPrepMinutes != null) 'avgPrepMinutes': avgPrepMinutes,
      };

  static DeliveryConfig? fromFirestore(Map<String, dynamic>? m) {
    if (m == null) return null;
    final offers = m['offersDelivery'] as bool? ?? false;
    final manageFromAccount = m['manageFromAccount'] as bool? ?? false;
    if (!offers) {
      return DeliveryConfig(
        offersDelivery: false,
        isFree: m['isFree'] as bool? ?? false,
        manageFromAccount: manageFromAccount,
        avgPrepMinutes: m['avgPrepMinutes'] as int?,
      );
    }
    return DeliveryConfig(
      offersDelivery: true,
      isFree: m['isFree'] as bool? ?? true,
      manageFromAccount: manageFromAccount,
      pricingMode: DeliveryPricingMode.tryParse(m['pricingMode'] as String?),
      priceEgp: (m['priceEgp'] as num?)?.toDouble(),
      innerCityFeeEgp: (m['innerCityFeeEgp'] as num?)?.toDouble(),
      outerCityFeeEgp: (m['outerCityFeeEgp'] as num?)?.toDouble(),
      avgPrepMinutes: m['avgPrepMinutes'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        offersDelivery,
        isFree,
        manageFromAccount,
        pricingMode,
        priceEgp,
        innerCityFeeEgp,
        outerCityFeeEgp,
        avgPrepMinutes,
      ];
}
