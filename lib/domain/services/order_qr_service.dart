import 'package:cloud_functions/cloud_functions.dart';

class OrderQrService {
  OrderQrService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<String?> fetchPickupToken({
    required String masterOrderId,
    required String providerId,
    String? driverId,
  }) async {
    final callable = _functions.httpsCallable('getOrderQrTokens');
    final result = await callable.call<Map<String, dynamic>>({
      'masterOrderId': masterOrderId,
      'providerId': providerId,
      if (driverId != null && driverId.trim().isNotEmpty)
        'driverId': driverId.trim(),
      'purpose': 'pickup',
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['token'] as String?;
  }
}
