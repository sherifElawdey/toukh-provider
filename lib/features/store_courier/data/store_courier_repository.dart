import 'package:cloud_functions/cloud_functions.dart';

/// How the recipient pays for the order itself (the delivery fee is always
/// paid by the store).
enum CourierPaymentMethod {
  /// The courier collects the order price from the recipient.
  cash('cash'),

  /// Already paid to the store: the courier collects nothing.
  prepaid('prepaid');

  const CourierPaymentMethod(this.wire);
  final String wire;
}

/// A delivery address picked on the map, plus the store's notes for it.
class CourierDestination {
  const CourierDestination({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    this.details = '',
  });

  final double lat;
  final double lng;
  final String formattedAddress;

  /// Building, floor, landmark… typed by the store.
  final String details;

  CourierDestination copyWith({String? formattedAddress, String? details}) {
    return CourierDestination(
      lat: lat,
      lng: lng,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    'formattedAddress': formattedAddress,
    if (details.trim().isNotEmpty) 'details': details.trim(),
  };
}

class CourierQuote {
  const CourierQuote({
    required this.deliveryFeeEgp,
    required this.distanceMeters,
  });

  final double deliveryFeeEgp;
  final double distanceMeters;
}

/// "Request a courier to deliver your order" (see `storeCourierOrder.js`).
class StoreCourierRepository {
  StoreCourierRepository(this._functions);

  final FirebaseFunctions _functions;

  /// Havit's fee from the store to [destination]; the store pays it in cash.
  Future<CourierQuote> quote({
    required CourierDestination destination,
    required double orderPriceEgp,
  }) async {
    final res = await _functions
        .httpsCallable('quoteStoreCourierDelivery')
        .call<Map<String, dynamic>>({
          'destination': destination.toMap(),
          'orderPriceEgp': orderPriceEgp,
        });
    final data = res.data;
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    return CourierQuote(
      deliveryFeeEgp: n(data['deliveryFeeEgp']),
      distanceMeters: n(data['distanceMeters']),
    );
  }

  /// Starts the courier search (the store pays the fee in cash at pickup).
  /// Returns the new order id.
  Future<String> create({
    required CourierDestination destination,
    required double orderPriceEgp,
    required String recipientPhone,
    CourierPaymentMethod paymentMethod = CourierPaymentMethod.cash,
    String? recipientName,
    String? note,
  }) async {
    final res = await _functions
        .httpsCallable('createStoreCourierOrder')
        .call<Map<String, dynamic>>({
          'destination': destination.toMap(),
          'orderPriceEgp': orderPriceEgp,
          'recipientPhone': recipientPhone.trim(),
          'paymentMethod': paymentMethod.wire,
          if (recipientName != null && recipientName.trim().isNotEmpty)
            'recipientName': recipientName.trim(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        });
    return '${res.data['orderId']}';
  }
}
