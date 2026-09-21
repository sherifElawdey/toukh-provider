import 'dart:convert';

import '../orders/toukh_firestore_timestamps.dart';
import 'toukh_fcm_data_keys.dart';
import 'toukh_notification.dart';

/// Maps [ToukhNotification] to/from Firestore maps (no Timestamp types here).
abstract final class ToukhNotificationMapper {
  ToukhNotificationMapper._();

  static Map<String, dynamic> toFirestore(ToukhNotificationTemplate template) {
    return {
      'title': template.title,
      'description': template.description,
      if (template.imageUrl != null && template.imageUrl!.isNotEmpty)
        'imageUrl': template.imageUrl,
      if (template.link != null && template.link!.isNotEmpty) 'link': template.link,
      'rootRoute': template.rootRoute,
      'payload': template.payload,
      'opened': false,
      'openedAt': null,
      if (template.type != null) 'type': template.type,
      if (template.orderId != null) 'orderId': template.orderId,
      'category': template.category,
    };
  }

  static ToukhNotification fromFirestore(String id, Map<String, dynamic> data) {
    return ToukhNotification(
      id: id,
      title: _string(data['title']) ?? '',
      description: _string(data['description']) ?? _string(data['body']) ?? '',
      imageUrl: _string(data['imageUrl']),
      link: _string(data['link']),
      rootRoute: _string(data['rootRoute']) ?? '',
      payload: _payloadMap(data['payload']),
      opened: data['opened'] == true,
      openedAt: _date(data['openedAt']),
      createdAt: _date(data['createdAt']),
      type: _string(data['type']),
      orderId: _string(data['orderId']),
      category: _string(data['category']) ?? 'order',
    );
  }

  /// Build from FCM data map (string values).
  static ToukhNotification? fromFcmData(Map<String, dynamic> data) {
    final id = _string(data[ToukhFcmDataKeys.notificationId]);
    if (id == null || id.isEmpty) return null;

    Map<String, dynamic> payload = {};
    final payloadRaw = _string(data[ToukhFcmDataKeys.payloadJson]);
    if (payloadRaw != null && payloadRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(payloadRaw);
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    return ToukhNotification(
      id: id,
      title: _string(data['title']) ?? '',
      description: _string(data['body']) ?? _string(data['description']) ?? '',
      imageUrl: _string(data[ToukhFcmDataKeys.imageUrl]),
      link: _string(data[ToukhFcmDataKeys.link]),
      rootRoute: _string(data[ToukhFcmDataKeys.rootRoute]) ?? '',
      payload: payload,
      type: _string(data[ToukhFcmDataKeys.type]),
      orderId: _string(data[ToukhFcmDataKeys.orderId]) ??
          _string(payload['orderId'] as String?),
    );
  }

  static Map<String, String> toFcmData({
    required String notificationId,
    required ToukhNotification notification,
  }) {
    return {
      ToukhFcmDataKeys.notificationId: notificationId,
      ToukhFcmDataKeys.rootRoute: notification.rootRoute,
      ToukhFcmDataKeys.payloadJson: jsonEncode(notification.payload),
      if (notification.imageUrl != null)
        ToukhFcmDataKeys.imageUrl: notification.imageUrl!,
      if (notification.link != null) ToukhFcmDataKeys.link: notification.link!,
      if (notification.type != null) ToukhFcmDataKeys.type: notification.type!,
      if (notification.orderId != null)
        ToukhFcmDataKeys.orderId: notification.orderId!,
      ToukhFcmDataKeys.category: notification.category,
    };
  }

  static Map<String, dynamic> _payloadMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  static DateTime? _date(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}
