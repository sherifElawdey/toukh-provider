import 'dart:math' as math;

import 'cart_line_for_split.dart';
import 'provider_delivery_config.dart';

class DeliveryFeeBreakdown {
  const DeliveryFeeBreakdown({
    required this.perProviderFees,
    required this.aggregatedFeeEgp,
    required this.totalDeliveryFeeEgp,
  });

  final Map<String, double> perProviderFees;
  final double aggregatedFeeEgp;
  final double totalDeliveryFeeEgp;
}

/// Calculates delivery fees per provider (not per item).
abstract final class DeliveryFeeCalculator {
  /// Platform / courier legacy fixed fee (not used when a route quote exists).
  static double feeForCourierProvider(ProviderDeliveryConfig config) {
    if (config.freeDelivery) return 0;
    return config.deliveryFeeEgp;
  }

  /// Store-fleet fee from provider [deliveryConfig] (fixed or per-km).
  static double feeForStoreProvider(
    ProviderDeliveryConfig config, {
    double? customerLat,
    double? customerLng,
  }) {
    if (!config.offersDelivery) return 0;
    if (config.freeDelivery) return 0;

    if (config.pricingMode == StoreDeliveryPricingMode.perKm) {
      if (customerLat == null ||
          customerLng == null ||
          !config.hasStoreCoords) {
        // Without distance, fall back to 0 rather than inventing a fee.
        return 0;
      }
      final km = haversineKm(
        config.storeLat!,
        config.storeLng!,
        customerLat,
        customerLng,
      );
      return (km * config.deliveryFeeEgp).roundToDouble();
    }

    return config.deliveryFeeEgp;
  }

  /// @deprecated Prefer [feeForCourierProvider] / [feeForStoreProvider].
  static double feeForProvider(ProviderDeliveryConfig config) {
    if (config.offersDelivery) {
      return feeForStoreProvider(config);
    }
    return feeForCourierProvider(config);
  }

  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  /// [providerIds] participating in aggregated courier group.
  static DeliveryFeeBreakdown calculate({
    required List<CartLineForSplit> lines,
    required Map<String, ProviderDeliveryConfig> configs,
    required Set<String> storeDeliveryProviderIds,
    required Set<String> aggregatedCourierProviderIds,
    double platformFeeEgp = 0,
    double? customerLat,
    double? customerLng,
  }) {
    final perProvider = <String, double>{};
    var aggregated = 0.0;

    for (final pid in aggregatedCourierProviderIds) {
      final cfg = configs[pid] ?? ProviderDeliveryConfig(providerId: pid);
      final fee = feeForCourierProvider(cfg);
      perProvider[pid] = fee;
      aggregated += fee;
    }

    for (final pid in storeDeliveryProviderIds) {
      final cfg = configs[pid] ?? ProviderDeliveryConfig(providerId: pid);
      perProvider[pid] = feeForStoreProvider(
        cfg,
        customerLat: customerLat,
        customerLng: customerLng,
      );
    }

    // Independent courier providers (case 3a) — each gets own fee
    final lineProviders = lines.map((l) => l.providerId).toSet();
    for (final pid in lineProviders) {
      if (storeDeliveryProviderIds.contains(pid)) continue;
      if (aggregatedCourierProviderIds.contains(pid)) continue;
      final cfg = configs[pid] ?? ProviderDeliveryConfig(providerId: pid);
      final fee = feeForCourierProvider(cfg);
      perProvider[pid] = fee;
    }

    final independentFees = perProvider.entries
        .where((e) => !aggregatedCourierProviderIds.contains(e.key))
        .fold<double>(0, (sum, e) => sum + e.value);

    final total = independentFees + aggregated + platformFeeEgp;

    return DeliveryFeeBreakdown(
      perProviderFees: perProvider,
      aggregatedFeeEgp: aggregated + platformFeeEgp,
      totalDeliveryFeeEgp: total,
    );
  }
}
