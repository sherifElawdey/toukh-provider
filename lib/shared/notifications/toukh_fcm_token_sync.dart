import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'toukh_fcm_apns.dart';
import 'toukh_notification_recipient.dart';

/// Merges and persists FCM device tokens on user/provider/driver profiles.
abstract final class ToukhFcmTokenSync {
  ToukhFcmTokenSync._();

  static const int maxFcmTokens = 5;

  /// Returns [existing] when [newToken] is already present; otherwise appends
  /// [newToken] and drops the oldest entries until length is at most [maxFcmTokens].
  static List<String> mergeFcmToken(List<String> existing, String newToken) {
    final list = existing.where((t) => t.isNotEmpty).toList();
    if (list.contains(newToken)) return list;
    final updated = [...list, newToken];
    while (updated.length > maxFcmTokens) {
      updated.removeAt(0);
    }
    return updated;
  }

  /// Registers the current device FCM token on the profile when it is not
  /// already in [existingFcmTokens].
  static Future<bool> syncIfNeeded({
    required String uid,
    required List<String> existingFcmTokens,
    required FirebaseFirestore firestore,
    required ToukhNotificationRecipient recipient,
    Future<String?> Function()? getCurrentToken,
  }) async {
    try {
      final token = await (getCurrentToken ?? ToukhFcmApns.getToken)();
      if (token == null || token.isEmpty) {
        debugPrint(
          'ToukhFcmTokenSync.syncIfNeeded: no FCM token yet '
          '(uid=$uid recipient=${recipient.name})',
        );
        return false;
      }
      if (existingFcmTokens.contains(token)) {
        debugPrint(
          'ToukhFcmTokenSync: token already on ${recipient.collectionName}/$uid',
        );
        return true;
      }

      // Atomic add first (survives concurrent writers), then trim if needed.
      final ref = firestore.collection(recipient.collectionName).doc(uid);
      await ref.set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final snap = await ref.get();
      final live = (snap.data()?['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((t) => t.isNotEmpty)
              .toList() ??
          <String>[];
      if (live.length > maxFcmTokens) {
        final trimmed = live.sublist(live.length - maxFcmTokens);
        await ref.set(
          {
            'fcmTokens': trimmed,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      debugPrint(
        'ToukhFcmTokenSync: saved token on ${recipient.collectionName}/$uid '
        '(len=${live.length.clamp(0, maxFcmTokens)})',
      );
      return true;
    } catch (e, st) {
      debugPrint('ToukhFcmTokenSync.syncIfNeeded failed: $e\n$st');
      return false;
    }
  }

  /// Reads live [fcmTokens] from Firestore, then registers the current device
  /// token when it is not already in the profile list.
  static Future<bool> syncOnAppOpen({
    required String uid,
    required FirebaseFirestore firestore,
    required ToukhNotificationRecipient recipient,
    Future<String?> Function()? getCurrentToken,
  }) async {
    try {
      final snap =
          await firestore.collection(recipient.collectionName).doc(uid).get();
      final data = snap.data();
      final existing = (data?['fcmTokens'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((t) => t.isNotEmpty)
              .toList() ??
          <String>[];
      return syncIfNeeded(
        uid: uid,
        existingFcmTokens: existing,
        firestore: firestore,
        recipient: recipient,
        getCurrentToken: getCurrentToken,
      );
    } catch (e, st) {
      debugPrint('ToukhFcmTokenSync.syncOnAppOpen failed: $e\n$st');
      return false;
    }
  }

  /// Removes this device's current FCM token from the profile list (sign-out).
  static Future<void> removeCurrentDeviceToken({
    required String uid,
    required FirebaseFirestore firestore,
    required ToukhNotificationRecipient recipient,
    Future<String?> Function()? getCurrentToken,
  }) async {
    try {
      final token = await (getCurrentToken ?? ToukhFcmApns.getToken)();
      if (token == null || token.isEmpty) return;

      final ref = firestore.collection(recipient.collectionName).doc(uid);
      await ref.set(
        {
          'fcmTokens': FieldValue.arrayRemove([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint(
        'ToukhFcmTokenSync: removed token from ${recipient.collectionName}/$uid',
      );
    } catch (e, st) {
      debugPrint('ToukhFcmTokenSync.removeCurrentDeviceToken failed: $e\n$st');
    }
  }
}
