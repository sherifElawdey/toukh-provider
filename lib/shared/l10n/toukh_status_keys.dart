/// Canonical GetX translation keys for order / request / ride statuses.
///
/// Apps must define EN+AR values for these keys. Pass the Firestore wire
/// string (or alias); helpers normalize then return `status.<domain>.<wire>`.
abstract final class ToukhStatusKeys {
  ToukhStatusKeys._();

  static const _orderPrefix = 'status.order.';
  static const _providerPrefix = 'status.provider.';
  static const _homeServicePrefix = 'status.home_service.';
  static const _ridePrefix = 'status.ride.';
  static const _deliveryPrefix = 'status.delivery.';

  static const _orderAliases = <String, String>{
    'placed': 'pending',
    'courier_assigned': 'driver_assigned',
    'out_for_delivery': 'on_the_way',
    'completed': 'delivered',
    'canceled': 'cancelled',
  };

  static const _providerAliases = <String, String>{
    'placed': 'pending',
    'new': 'pending',
    'ready': 'ready_for_pickup',
    'completed': 'delivered',
    'canceled': 'cancelled',
  };

  static const _homeServiceAliases = <String, String>{
    'canceled': 'cancelled',
    'rejected': 'declined',
  };

  static const _rideAliases = <String, String>{
    'canceled': 'cancelled',
  };

  static const _deliveryAliases = <String, String>{
    'canceled': 'cancelled',
    'out_for_delivery': 'on_the_way',
    'completed': 'delivered',
  };

  static String order(String? raw) =>
      '$_orderPrefix${_normalize(raw, _orderAliases)}';

  static String provider(String? raw) =>
      '$_providerPrefix${_normalize(raw, _providerAliases)}';

  static String homeService(String? raw) =>
      '$_homeServicePrefix${_normalize(raw, _homeServiceAliases)}';

  static String ride(String? raw) =>
      '$_ridePrefix${_normalize(raw, _rideAliases)}';

  static String delivery(String? raw) =>
      '$_deliveryPrefix${_normalize(raw, _deliveryAliases)}';

  /// Prefer [order] / [provider] / etc. This is for unknown domains.
  static String unknown(String? raw) {
    final w = _wire(raw);
    return w.isEmpty ? 'status.unknown' : 'status.unknown.$w';
  }

  static String _normalize(String? raw, Map<String, String> aliases) {
    final w = _wire(raw);
    if (w.isEmpty) return 'unknown';
    return aliases[w] ?? w;
  }

  static String _wire(String? raw) {
    if (raw == null) return '';
    return raw.trim().toLowerCase().replaceAll(' ', '_');
  }
}
