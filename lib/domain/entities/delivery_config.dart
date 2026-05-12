import 'package:equatable/equatable.dart';

enum DeliveryPricingMode {
  fixed,
  perKm;

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
    this.pricingMode,
    this.priceEgp,
    this.avgPrepMinutes,
  });

  final bool offersDelivery;
  final bool isFree;
  final DeliveryPricingMode? pricingMode;
  final double? priceEgp;
  final int? avgPrepMinutes;

  Map<String, dynamic> toFirestore() => {
        'offersDelivery': offersDelivery,
        'isFree': isFree,
        if (pricingMode != null) 'pricingMode': pricingMode!.wireValue,
        if (priceEgp != null) 'priceEgp': priceEgp,
        if (avgPrepMinutes != null) 'avgPrepMinutes': avgPrepMinutes,
      };

  static DeliveryConfig? fromFirestore(Map<String, dynamic>? m) {
    if (m == null) return null;
    final offers = m['offersDelivery'] as bool? ?? false;
    if (!offers) {
      return DeliveryConfig(
        offersDelivery: false,
        isFree: true,
        avgPrepMinutes: m['avgPrepMinutes'] as int?,
      );
    }
    return DeliveryConfig(
      offersDelivery: true,
      isFree: m['isFree'] as bool? ?? true,
      pricingMode: DeliveryPricingMode.tryParse(m['pricingMode'] as String?),
      priceEgp: (m['priceEgp'] as num?)?.toDouble(),
      avgPrepMinutes: m['avgPrepMinutes'] as int?,
    );
  }

  @override
  List<Object?> get props =>
      [offersDelivery, isFree, pricingMode, priceEgp, avgPrepMinutes];
}
