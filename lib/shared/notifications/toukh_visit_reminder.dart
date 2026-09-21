import 'dart:convert';

import 'toukh_fcm_data_keys.dart';
import 'toukh_home_service_notification_types.dart';
import 'toukh_notification_routes.dart';

/// Who the visit reminder is for (affects copy and notification id namespace).
enum VisitReminderRole {
  customer,
  provider,
}

/// A home-service visit that should have a local scheduled reminder.
class VisitReminderTarget {
  const VisitReminderTarget({
    required this.requestId,
    required this.visitDate,
  });

  final String requestId;
  final DateTime visitDate;
}

/// Parsed FCM / local payload for scheduling a visit reminder.
class VisitReminderScheduleRequest {
  const VisitReminderScheduleRequest({
    required this.role,
    required this.requestId,
    required this.visitDate,
  });

  final VisitReminderRole role;
  final String requestId;
  final DateTime visitDate;

  /// Parses FCM data (string values) for [home_service_request_accepted].
  ///
  /// Provider role is assumed for FCM (customer schedules locally on accept).
  static VisitReminderScheduleRequest? tryParseFcmData(
    Map<String, dynamic> data, {
    VisitReminderRole role = VisitReminderRole.provider,
  }) {
    final type = _string(data[ToukhFcmDataKeys.type]);
    if (type != ToukhHomeServiceNotificationTypes.homeServiceRequestAccepted) {
      return null;
    }

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

    final requestId = _string(data[ToukhFcmDataKeys.requestId]) ??
        _string(data[ToukhFcmDataKeys.orderId]) ??
        _string(payload[ToukhFcmDataKeys.requestId]) ??
        _string(payload[ToukhFcmDataKeys.orderId]);
    if (requestId == null || requestId.isEmpty) return null;

    final visitDate = _parseDate(data[ToukhFcmDataKeys.visitDate]) ??
        _parseDate(payload[ToukhFcmDataKeys.visitDate]) ??
        _parseDate(payload['scheduledAt']);
    if (visitDate == null) return null;

    return VisitReminderScheduleRequest(
      role: role,
      requestId: requestId,
      visitDate: visitDate,
    );
  }

  static String? _string(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is DateTime) return v.toUtc();
    if (v is! String || v.trim().isEmpty) return null;
    return DateTime.tryParse(v.trim())?.toUtc();
  }
}

/// Copy and deep-link helpers for visit reminders.
abstract final class ToukhVisitReminderCopy {
  ToukhVisitReminderCopy._();

  static String title(VisitReminderRole role) => switch (role) {
        VisitReminderRole.provider => 'زيارة قادمة',
        VisitReminderRole.customer => 'خدمة قادمة',
      };

  static String body(VisitReminderRole role, String requestId) => switch (role) {
        VisitReminderRole.provider =>
          'لديك زيارة مجدولة اليوم للطلب رقم #$requestId.',
        VisitReminderRole.customer =>
          'زيارتك المنزلية المجدولة اليوم.',
      };

  static String rootRoute(VisitReminderRole role, String requestId) =>
      switch (role) {
        VisitReminderRole.provider =>
          ToukhNotificationRoutes.providerHomeServiceRequestDetail(requestId),
        VisitReminderRole.customer =>
          ToukhNotificationRoutes.consumerHomeServiceRequestDetail,
      };

  static Map<String, dynamic> tapPayload({
    required VisitReminderRole role,
    required String requestId,
    required DateTime visitDate,
  }) {
    final route = rootRoute(role, requestId);
    return {
      ToukhFcmDataKeys.notificationId: 'home_service_visit_${role.name}_$requestId',
      ToukhFcmDataKeys.type:
          ToukhHomeServiceNotificationTypes.homeServiceRequestAccepted,
      ToukhFcmDataKeys.orderId: requestId,
      ToukhFcmDataKeys.requestId: requestId,
      ToukhFcmDataKeys.visitDate: visitDate.toUtc().toIso8601String(),
      ToukhFcmDataKeys.category: 'home_service',
      ToukhFcmDataKeys.rootRoute: route,
      'title': title(role),
      'body': body(role, requestId),
      'role': role.name,
      ToukhFcmDataKeys.payloadJson: jsonEncode({
        'requestId': requestId,
        'orderId': requestId,
        'visitDate': visitDate.toUtc().toIso8601String(),
        'role': role.name,
      }),
    };
  }
}
