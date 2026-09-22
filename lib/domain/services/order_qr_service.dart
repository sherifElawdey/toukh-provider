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

  /// Returns existing store↔driver [pickupCode], minting one if missing.
  Future<String?> ensurePickupCode(String masterOrderId) async {
    final callable = _functions.httpsCallable('ensurePickupCode');
    final result = await callable.call<Map<String, dynamic>>({
      'masterOrderId': masterOrderId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final code = (data['pickupCode'] ?? '').toString().trim();
    return code.isEmpty ? null : code;
  }

  Future<void> verifyDeliveryQr(String qrPayload) async {
    final callable = _functions.httpsCallable('verifyDeliveryQr');
    await callable.call({'qrPayload': qrPayload});
  }
}
