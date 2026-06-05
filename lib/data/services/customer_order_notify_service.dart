import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Triggers server-side FCM to the order owner after a status change.
class CustomerOrderNotifyService {
  CustomerOrderNotifyService(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<void> notifyCustomer({
    required String providerId,
    required String orderId,
  }) async {
    try {
      final callable = _functions.httpsCallable('notifyCustomerOrderStatus');
      await callable.call<Map<String, dynamic>>({
        'providerId': providerId,
        'orderId': orderId,
      });
      if (kDebugMode) {
        debugPrint('notifyCustomerOrderStatus ✓ $providerId/$orderId');
      }
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') {
        debugPrint(
          'notifyCustomerOrderStatus: function not deployed — using client inbox fallback.',
        );
        await _deliverClientFallback(providerId: providerId, orderId: orderId);
        return;
      }
      debugPrint('notifyCustomerOrderStatus failed: ${e.code} ${e.message}');
    } catch (e, st) {
      debugPrint('notifyCustomerOrderStatus failed: $e\n$st');
    }
  }

  Future<void> _deliverClientFallback({
    required String providerId,
    required String orderId,
  }) async {
    try {
      final writer = ToukhInboxNotificationWriter(_firestore);
      final providerImageUrl = await writer.fetchProviderImageUrl(providerId);
      await writer.deliverCustomerStatusIfNeeded(
        providerId: providerId,
        orderId: orderId,
        providerImageUrl: providerImageUrl,
      );
    } catch (e, st) {
      debugPrint(
        'CustomerOrderNotifyService client fallback failed '
        '$providerId/$orderId: $e\n$st',
      );
    }
  }
}
