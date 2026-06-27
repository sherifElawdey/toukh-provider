import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Writes customer inbox notification when provider sends a home service quote.
class CustomerHomeServiceQuoteNotifyService {
  CustomerHomeServiceQuoteNotifyService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> notifyQuote({required String requestId}) async {
    if (requestId.trim().isEmpty) return;
    try {
      final writer = ToukhInboxNotificationWriter(_firestore);
      final snap = await _firestore
          .collection(ToukhHomeServiceNotificationTemplates
              .homeServiceRequestsCollection())
          .doc(requestId)
          .get();
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final providerId = data['providerId']?.toString();
      String? providerImageUrl;
      if (providerId != null && providerId.isNotEmpty) {
        providerImageUrl = await writer.fetchProviderImageUrl(providerId);
      }
      await writer.deliverCustomerHomeServiceQuoteIfNeeded(
        requestId: requestId,
        providerImageUrl: providerImageUrl,
      );
      if (kDebugMode) {
        debugPrint(
          'CustomerHomeServiceQuoteNotifyService ✓ request=$requestId',
        );
      }
    } catch (e, st) {
      debugPrint('CustomerHomeServiceQuoteNotifyService failed: $e\n$st');
    }
  }
}
