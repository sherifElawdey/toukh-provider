import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Writes customer inbox notification when provider marks on my way.
class CustomerHomeServiceOnMyWayNotifyService {
  CustomerHomeServiceOnMyWayNotifyService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> notifyOnMyWay({required String requestId}) async {
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
      await writer.deliverCustomerHomeServiceOnMyWayIfNeeded(
        requestId: requestId,
        providerImageUrl: providerImageUrl,
      );
      if (kDebugMode) {
        debugPrint(
          'CustomerHomeServiceOnMyWayNotifyService ✓ request=$requestId',
        );
      }
    } catch (e, st) {
      debugPrint('CustomerHomeServiceOnMyWayNotifyService failed: $e\n$st');
    }
  }
}
