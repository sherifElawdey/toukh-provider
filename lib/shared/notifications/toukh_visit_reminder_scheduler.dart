import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'toukh_push_config.dart';
import 'toukh_visit_reminder.dart';

/// Schedules persistent local visit reminders for home-service requests.
///
/// Safe to call from the FCM background isolate via [tryScheduleFromFcmData].
///
/// iOS note: when the app is terminated and FCM includes a `notification`
/// block, iOS may not run the Dart background handler. Callers must also
/// [restorePendingNotifications] on cold start / auth.
class ToukhVisitReminderScheduler {
  ToukhVisitReminderScheduler._();

  static final ToukhVisitReminderScheduler instance =
      ToukhVisitReminderScheduler._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timeZonesReady = false;

  /// Initializes the plugin and timezone database (idempotent).
  Future<void> ensureInitialized() async {
    if (kIsWeb) return;
    if (_initialized) return;

    _ensureTimeZones();

    final android = AndroidInitializationSettings(
      '@mipmap/${ToukhPushConfig.androidIcon}',
    );
    await _plugin.initialize(
      InitializationSettings(
        android: android,
        iOS: const DarwinInitializationSettings(),
      ),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        ToukhPushConfig.visitReminderChannelId,
        ToukhPushConfig.visitReminderChannelName,
        description: ToukhPushConfig.visitReminderChannelDescription,
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// Schedules (or replaces) a visit reminder for [requestId].
  Future<void> scheduleVisitReminder({
    required VisitReminderRole role,
    required String requestId,
    required DateTime visitDate,
  }) async {
    if (kIsWeb) return;
    final id = requestId.trim();
    if (id.isEmpty) return;

    final when = visitDate.toUtc();
    if (!when.isAfter(DateTime.now().toUtc())) {
      debugPrint('Visit reminder skipped (past): $id @ $when');
      return;
    }

    await ensureInitialized();

    final notificationId = notificationIdFor(role: role, requestId: id);
    final title = ToukhVisitReminderCopy.title(role);
    final body = ToukhVisitReminderCopy.body(role, id);
    final payload = jsonEncode(
      ToukhVisitReminderCopy.tapPayload(
        role: role,
        requestId: id,
        visitDate: when,
      ),
    );

    // Absolute instant → device-local zone (tz.local set in _ensureTimeZones).
    final scheduled = tz.TZDateTime.from(when, tz.local);
    final details = _details();

    try {
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint(
        'Visit reminder exact schedule failed, falling back to inexact: $e',
      );
      try {
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          scheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e2, st) {
        debugPrint('Visit reminder schedule failed: $e2\n$st');
      }
    }
  }

  /// Cancels a previously scheduled reminder for [requestId].
  Future<void> cancelVisitReminder({
    required VisitReminderRole role,
    required String requestId,
  }) async {
    if (kIsWeb) return;
    final id = requestId.trim();
    if (id.isEmpty) return;

    await ensureInitialized();
    await _plugin.cancel(notificationIdFor(role: role, requestId: id));
  }

  /// Replaces any existing reminder with a new [visitDate].
  Future<void> rescheduleVisitReminder({
    required VisitReminderRole role,
    required String requestId,
    required DateTime visitDate,
  }) async {
    await cancelVisitReminder(role: role, requestId: requestId);
    await scheduleVisitReminder(
      role: role,
      requestId: requestId,
      visitDate: visitDate,
    );
  }

  /// Ensures every accepted visit in [targets] has a scheduled reminder.
  ///
  /// Uses schedule (same id replaces) so duplicates are never created.
  Future<void> restorePendingNotifications({
    required VisitReminderRole role,
    required List<VisitReminderTarget> targets,
  }) async {
    if (kIsWeb) return;
    for (final target in targets) {
      await scheduleVisitReminder(
        role: role,
        requestId: target.requestId,
        visitDate: target.visitDate,
      );
    }
  }

  /// Syncs scheduled reminders with the current set of accepted visits.
  ///
  /// Schedules/reschedules [accepted], cancels [knownRequestIds] that are no
  /// longer accepted.
  Future<void> syncVisitReminders({
    required VisitReminderRole role,
    required List<VisitReminderTarget> accepted,
    required Set<String> knownRequestIds,
  }) async {
    if (kIsWeb) return;

    final acceptedIds = <String>{};
    for (final target in accepted) {
      acceptedIds.add(target.requestId);
      await scheduleVisitReminder(
        role: role,
        requestId: target.requestId,
        visitDate: target.visitDate,
      );
    }

    for (final id in knownRequestIds) {
      if (!acceptedIds.contains(id)) {
        await cancelVisitReminder(role: role, requestId: id);
      }
    }
  }

  /// Background-isolate entry: schedule from FCM data if applicable.
  static Future<void> tryScheduleFromFcmData(
    Map<String, dynamic> data, {
    VisitReminderRole role = VisitReminderRole.provider,
  }) async {
    if (kIsWeb) return;
    final request = VisitReminderScheduleRequest.tryParseFcmData(
      data,
      role: role,
    );
    if (request == null) return;

    await instance.scheduleVisitReminder(
      role: request.role,
      requestId: request.requestId,
      visitDate: request.visitDate,
    );
  }

  /// Deterministic positive notification id for [role] + [requestId].
  static int notificationIdFor({
    required VisitReminderRole role,
    required String requestId,
  }) {
    // Namespace by role so customer/provider apps never collide if both run
    // on the same device with the same request id.
    final namespace = role == VisitReminderRole.provider ? 0x50000000 : 0x40000000;
    final hash = Object.hash(role.name, requestId) & 0x0fffffff;
    return namespace | hash;
  }

  void _ensureTimeZones() {
    if (_timeZonesReady) return;
    tz_data.initializeTimeZones();
    // Toukh operates in Egypt; Africa/Cairo handles EET/EEST. Fall back to a
    // fixed-offset location matching the device when the named zone is missing.
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    } catch (_) {
      try {
        final offsetHours = DateTime.now().timeZoneOffset.inHours;
        // Etc/GMT signs are inverted (Etc/GMT-2 == UTC+2).
        final etcName = offsetHours >= 0
            ? 'Etc/GMT-${offsetHours.abs()}'
            : 'Etc/GMT+${offsetHours.abs()}';
        tz.setLocalLocation(tz.getLocation(etcName));
      } catch (e) {
        debugPrint('Visit reminder timezone fallback failed: $e');
      }
    }
    _timeZonesReady = true;
  }

  NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        ToukhPushConfig.visitReminderChannelId,
        ToukhPushConfig.visitReminderChannelName,
        channelDescription: ToukhPushConfig.visitReminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
