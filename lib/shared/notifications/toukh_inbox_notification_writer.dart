import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../firestore/toukh_firestore_collections.dart';
import '../orders/toukh_firestore_timestamps.dart';
import '../orders/toukh_order_paths.dart';
import 'toukh_notification.dart';
import 'toukh_notification_mapper.dart';
import 'toukh_notification_paths.dart';
import 'toukh_notification_recipient.dart';
import 'toukh_home_service_notification_templates.dart';
import 'toukh_order_notification_templates.dart';

/// Client-side inbox delivery (Spark fallback when Cloud Functions are unavailable).
class ToukhInboxNotificationWriter {
  ToukhInboxNotificationWriter(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _masterRef(String masterOrderId) =>
      _firestore.collection(ToukhOrderPaths.masterOrders).doc(masterOrderId);

  CollectionReference<Map<String, dynamic>> _inboxRef(
    ToukhNotificationRecipient recipient,
    String uid,
  ) =>
      _firestore
          .doc(ToukhNotificationPaths.recipientDocPath(
            recipient: recipient,
            uid: uid,
          ))
          .collection(ToukhNotificationPaths.notificationsSubcollection);

  /// Writes a notification doc without idempotency guards.
  Future<String?> deliver({
    required ToukhNotificationRecipient recipient,
    required String recipientUid,
    required ToukhNotificationTemplate template,
  }) async {
    if (recipientUid.trim().isEmpty) return null;
    try {
      final doc = ToukhNotificationMapper.toFirestore(template);
      doc['createdAt'] = FieldValue.serverTimestamp();
      final ref = await _inboxRef(recipient, recipientUid).add(doc);
      return ref.id;
    } catch (e, st) {
      debugPrint('ToukhInboxNotificationWriter.deliver failed: $e\n$st');
      return null;
    }
  }

  /// Idempotent provider new-order inbox row (sets [providerPushSentAt] on slice).
  Future<String?> deliverProviderNewOrderIfNeeded({
    required String providerId,
    required String orderId,
    required Map<String, dynamic> order,
    String? customerPhotoUrl,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final masterRef = _masterRef(orderId);
        final masterSnap = await tx.get(masterRef);
        if (!masterSnap.exists) return null;

        final master = masterSnap.data() ?? {};
        final slices = Map<String, dynamic>.from(
          master['providerSlices'] as Map? ?? {},
        );
        final slice = Map<String, dynamic>.from(
          slices[providerId] as Map? ?? {},
        );
        if (slice.isEmpty) return null;
        if (slice['providerPushSentAt'] != null) return null;

        final template = ToukhOrderNotificationTemplates.buildProviderNewOrderTemplate(
          order: {...slice, ...order},
          providerId: providerId,
          orderId: orderId,
          customerPhotoUrl: customerPhotoUrl,
        );

        final inboxRef = _inboxRef(
          ToukhNotificationRecipient.provider,
          providerId,
        ).doc();

        final doc = ToukhNotificationMapper.toFirestore(template);
        doc['createdAt'] = FieldValue.serverTimestamp();
        tx.set(inboxRef, doc);

        slice['providerPushSentAt'] = FieldValue.serverTimestamp();
        slices[providerId] = slice;
        tx.update(masterRef, {'providerSlices': slices});

        return inboxRef.id;
      });
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter.deliverProviderNewOrderIfNeeded failed: $e\n$st',
      );
      return null;
    }
  }

  /// Idempotent customer order-placed inbox row (sets customerStatusPushAt.placed).
  Future<String?> deliverCustomerOrderPlacedIfNeeded({
    required String customerId,
    required String providerId,
    required String orderId,
    required Map<String, dynamic> order,
    String? providerImageUrl,
  }) async {
    return _deliverCustomerStatusGuarded(
      customerId: customerId,
      providerId: providerId,
      orderId: orderId,
      order: order,
      statusKey: 'placed',
      providerImageUrl: providerImageUrl,
      templateBuilder: (o) => ToukhOrderNotificationTemplates.buildCustomerOrderPlacedTemplate(
        order: o,
        providerId: providerId,
        orderId: orderId,
        providerImageUrl: providerImageUrl,
      ),
    );
  }

  /// Idempotent customer status inbox row (sets customerStatusPushAt.{status}).
  Future<String?> deliverCustomerStatusIfNeeded({
    required String providerId,
    required String orderId,
    Map<String, dynamic>? order,
    String? nextStatus,
    String? providerImageUrl,
  }) async {
    try {
      final masterRef = _masterRef(orderId);
      final masterSnap = await masterRef.get();
      if (!masterSnap.exists) return null;

      final master = masterSnap.data() ?? {};
      final slices = master['providerSlices'] as Map? ?? {};
      final sliceMap = slices[providerId] as Map?;
      final orderData = order ??
          (sliceMap != null
              ? Map<String, dynamic>.from(sliceMap)
              : <String, dynamic>{});
      final status = nextStatus ?? orderData['status']?.toString();
      if (status == null || status.isEmpty) return null;

      final customerId = ToukhOrderNotificationTemplates.resolveCustomerId(orderData);
      if (customerId == null) return null;

      final template = ToukhOrderNotificationTemplates.buildCustomerStatusTemplate(
        order: orderData,
        providerId: providerId,
        orderId: orderId,
        nextStatus: status,
        providerImageUrl: providerImageUrl,
      );
      if (template == null) return null;

      return _deliverCustomerStatusGuarded(
        customerId: customerId,
        providerId: providerId,
        orderId: orderId,
        order: orderData,
        statusKey: status,
        providerImageUrl: providerImageUrl,
        templateBuilder: (_) => template,
      );
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter.deliverCustomerStatusIfNeeded failed: $e\n$st',
      );
      return null;
    }
  }

  Future<String?> _deliverCustomerStatusGuarded({
    required String customerId,
    required String providerId,
    required String orderId,
    required Map<String, dynamic> order,
    required String statusKey,
    required ToukhNotificationTemplate Function(Map<String, dynamic> order)
        templateBuilder,
    String? providerImageUrl,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final masterRef = _masterRef(orderId);
        final masterSnap = await tx.get(masterRef);
        if (!masterSnap.exists) return null;

        final master = masterSnap.data() ?? {};
        final pushMap = master['customerStatusPushAt'];
        if (pushMap is Map && pushMap[statusKey] != null) return null;

        final slices = Map<String, dynamic>.from(
          master['providerSlices'] as Map? ?? {},
        );
        final slice = Map<String, dynamic>.from(
          slices[providerId] as Map? ?? order,
        );
        final slicePush = slice['customerStatusPushAt'];
        if (slicePush is Map && slicePush[statusKey] != null) return null;

        final template = templateBuilder({...slice, ...order});
        final inboxRef = _inboxRef(
          ToukhNotificationRecipient.customer,
          customerId,
        ).doc();

        final doc = ToukhNotificationMapper.toFirestore(template);
        doc['createdAt'] = FieldValue.serverTimestamp();
        tx.set(inboxRef, doc);
        tx.update(masterRef, {
          'customerStatusPushAt.$statusKey': FieldValue.serverTimestamp(),
        });

        return inboxRef.id;
      });
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter._deliverCustomerStatusGuarded failed: $e\n$st',
      );
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>> _homeServiceRequestRef(
    String requestId,
  ) =>
      _firestore
          .collection(ToukhHomeServiceNotificationTemplates.homeServiceRequestsCollection())
          .doc(requestId);

  /// Idempotent provider new home-service request inbox row (sets providerNotifiedAt).
  Future<String?> deliverProviderHomeServiceRequestIfNeeded({
    required String providerId,
    required String requestId,
    Map<String, dynamic>? request,
    String? customerPhotoUrl,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final requestRef = _homeServiceRequestRef(requestId);
        final requestSnap = await tx.get(requestRef);
        if (!requestSnap.exists) return null;

        final requestData = Map<String, dynamic>.from(requestSnap.data() ?? {});
        if (requestData['providerNotifiedAt'] != null) return null;

        final docProviderId = requestData['providerId']?.toString();
        if (docProviderId != providerId) return null;

        final merged = {...requestData, if (request != null) ...request};
        final template =
            ToukhHomeServiceNotificationTemplates.buildProviderNewRequestTemplate(
          request: merged,
          providerId: providerId,
          requestId: requestId,
          customerPhotoUrl: customerPhotoUrl,
        );

        final notificationId =
            ToukhHomeServiceNotificationTemplates.providerNewRequestNotificationId(
          requestId,
        );
        final inboxRef = _inboxRef(
          ToukhNotificationRecipient.provider,
          providerId,
        ).doc(notificationId);

        final existingInbox = await tx.get(inboxRef);
        if (existingInbox.exists) {
          tx.update(requestRef, {
            'providerNotifiedAt': FieldValue.serverTimestamp(),
          });
          return null;
        }

        final doc = ToukhNotificationMapper.toFirestore(template);
        doc['createdAt'] = FieldValue.serverTimestamp();
        tx.set(inboxRef, doc);
        tx.update(requestRef, {
          'providerNotifiedAt': FieldValue.serverTimestamp(),
        });

        return inboxRef.id;
      });
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter.deliverProviderHomeServiceRequestIfNeeded failed: $e\n$st',
      );
      return null;
    }
  }

  /// Idempotent customer home-service quote inbox row (sets customerQuoteNotifiedAt).
  Future<String?> deliverCustomerHomeServiceQuoteIfNeeded({
    required String requestId,
    String? providerImageUrl,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final requestRef = _homeServiceRequestRef(requestId);
        final requestSnap = await tx.get(requestRef);
        if (!requestSnap.exists) return null;

        final requestData = Map<String, dynamic>.from(requestSnap.data() ?? {});
        if (requestData['customerQuoteNotifiedAt'] != null) return null;

        final status = (requestData['status'] as String? ?? '').trim().toLowerCase();
        if (status != 'awaiting_customer') return null;

        final userId = requestData['userId']?.toString();
        if (userId == null || userId.isEmpty) return null;

        final merged = Map<String, dynamic>.from(requestData);
        final scheduledAt =
            ToukhFirestoreTimestamps.toDateTime(requestData['scheduledAt']);
        if (scheduledAt != null) {
          merged['scheduledAt'] = scheduledAt;
        }

        final template =
            ToukhHomeServiceNotificationTemplates.buildCustomerQuoteTemplate(
          request: merged,
          requestId: requestId,
          providerImageUrl: providerImageUrl,
        );

        final notificationId =
            ToukhHomeServiceNotificationTemplates.customerQuoteNotificationId(
          requestId,
        );
        final inboxRef = _inboxRef(
          ToukhNotificationRecipient.customer,
          userId,
        ).doc(notificationId);

        final existingInbox = await tx.get(inboxRef);
        if (existingInbox.exists) {
          tx.update(requestRef, {
            'customerQuoteNotifiedAt': FieldValue.serverTimestamp(),
          });
          return null;
        }

        final doc = ToukhNotificationMapper.toFirestore(template);
        doc['createdAt'] = FieldValue.serverTimestamp();
        tx.set(inboxRef, doc);
        tx.update(requestRef, {
          'customerQuoteNotifiedAt': FieldValue.serverTimestamp(),
        });

        return inboxRef.id;
      });
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter.deliverCustomerHomeServiceQuoteIfNeeded failed: $e\n$st',
      );
      return null;
    }
  }

  /// Idempotent customer home-service on-my-way inbox row (sets customerOnMyWayNotifiedAt).
  Future<String?> deliverCustomerHomeServiceOnMyWayIfNeeded({
    required String requestId,
    String? providerImageUrl,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final requestRef = _homeServiceRequestRef(requestId);
        final requestSnap = await tx.get(requestRef);
        if (!requestSnap.exists) return null;

        final requestData = Map<String, dynamic>.from(requestSnap.data() ?? {});
        if (requestData['customerOnMyWayNotifiedAt'] != null) return null;

        final status = (requestData['status'] as String? ?? '').trim().toLowerCase();
        if (status != 'in_progress') return null;

        final userId = requestData['userId']?.toString();
        if (userId == null || userId.isEmpty) return null;

        final merged = Map<String, dynamic>.from(requestData);
        final scheduledAt =
            ToukhFirestoreTimestamps.toDateTime(requestData['scheduledAt']);
        if (scheduledAt != null) {
          merged['scheduledAt'] = scheduledAt;
        }

        final template =
            ToukhHomeServiceNotificationTemplates.buildCustomerOnMyWayTemplate(
          request: merged,
          requestId: requestId,
          providerImageUrl: providerImageUrl,
        );

        final notificationId =
            ToukhHomeServiceNotificationTemplates.customerOnMyWayNotificationId(
          requestId,
        );
        final inboxRef = _inboxRef(
          ToukhNotificationRecipient.customer,
          userId,
        ).doc(notificationId);

        final existingInbox = await tx.get(inboxRef);
        if (existingInbox.exists) {
          tx.update(requestRef, {
            'customerOnMyWayNotifiedAt': FieldValue.serverTimestamp(),
          });
          return null;
        }

        final doc = ToukhNotificationMapper.toFirestore(template);
        doc['createdAt'] = FieldValue.serverTimestamp();
        tx.set(inboxRef, doc);
        tx.update(requestRef, {
          'customerOnMyWayNotifiedAt': FieldValue.serverTimestamp(),
        });

        return inboxRef.id;
      });
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter.deliverCustomerHomeServiceOnMyWayIfNeeded failed: $e\n$st',
      );
      return null;
    }
  }

  /// Idempotent provider home-service accepted inbox row
  /// (sets [providerAcceptedNotifiedAt]). Spark fallback when CF is unavailable.
  Future<String?> deliverProviderHomeServiceAcceptedIfNeeded({
    required String requestId,
  }) async {
    try {
      return await _firestore.runTransaction((tx) async {
        final requestRef = _homeServiceRequestRef(requestId);
        final requestSnap = await tx.get(requestRef);
        if (!requestSnap.exists) return null;

        final requestData = Map<String, dynamic>.from(requestSnap.data() ?? {});
        if (requestData['providerAcceptedNotifiedAt'] != null) return null;

        final status =
            (requestData['status'] as String? ?? '').trim().toLowerCase();
        if (status != 'accepted') return null;

        final providerId = requestData['providerId']?.toString();
        if (providerId == null || providerId.isEmpty) return null;

        final merged = Map<String, dynamic>.from(requestData);
        final scheduledAt =
            ToukhFirestoreTimestamps.toDateTime(requestData['scheduledAt']);
        if (scheduledAt != null) {
          merged['scheduledAt'] = scheduledAt;
        }

        final template =
            ToukhHomeServiceNotificationTemplates.buildProviderAcceptedTemplate(
          request: merged,
          requestId: requestId,
        );

        final notificationId =
            ToukhHomeServiceNotificationTemplates.providerAcceptedNotificationId(
          requestId,
        );
        final inboxRef = _inboxRef(
          ToukhNotificationRecipient.provider,
          providerId,
        ).doc(notificationId);

        final existingInbox = await tx.get(inboxRef);
        if (existingInbox.exists) {
          tx.update(requestRef, {
            'providerAcceptedNotifiedAt': FieldValue.serverTimestamp(),
          });
          return null;
        }

        final doc = ToukhNotificationMapper.toFirestore(template);
        doc['createdAt'] = FieldValue.serverTimestamp();
        tx.set(inboxRef, doc);
        tx.update(requestRef, {
          'providerAcceptedNotifiedAt': FieldValue.serverTimestamp(),
        });

        return inboxRef.id;
      });
    } catch (e, st) {
      debugPrint(
        'ToukhInboxNotificationWriter.deliverProviderHomeServiceAcceptedIfNeeded '
        'failed: $e\n$st',
      );
      return null;
    }
  }

  /// Best-effort provider profile image for customer notifications.
  Future<String?> fetchProviderImageUrl(String providerId) async {
    try {
      final snap = await _firestore
          .collection(ToukhFirestoreCollections.providers)
          .doc(providerId)
          .get();
      final data = snap.data();
      if (data == null) return null;
      for (final key in ['brandImageUrl', 'logoUrl', 'imageUrl', 'photoUrl']) {
        final url = data[key];
        if (url is String && url.trim().isNotEmpty) return url.trim();
      }
    } catch (_) {}
    return null;
  }
}
