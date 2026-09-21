import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'toukh_fcm_apns.dart';
import 'toukh_fcm_token_sync.dart';
import 'toukh_notification.dart';
import 'toukh_fcm_data_keys.dart';
import 'toukh_notification_mapper.dart';
import 'toukh_notification_recipient.dart';
import 'toukh_push_config.dart';
import 'toukh_visit_reminder_scheduler.dart';

typedef FcmTokenPersister = Future<void> Function(String uid, String token);
typedef NotificationTapHandler = Future<void> Function(ToukhNotification message);
typedef ForegroundNotificationHandler = bool Function(ToukhNotification message);

/// Shared FCM + local notifications bootstrap for Toukh apps.
class ToukhPushMessaging {
  ToukhPushMessaging._();

  static final ToukhPushMessaging instance = ToukhPushMessaging._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  FcmTokenPersister? _persistToken;
  NotificationTapHandler? _onTap;
  ForegroundNotificationHandler? _onForegroundNotification;
  ToukhNotificationRecipient? _recipient;
  FirebaseFirestore? _firestore;
  String? _syncedUid;
  String? _pendingSyncUid;
  bool _initialized = false;
  Future<void>? _syncInFlight;

  /// Shows a tray notification for background/data-only FCM (call after Firebase init).
  ///
  /// Also schedules a home-service visit reminder when the payload includes
  /// [home_service_request_accepted] + visitDate (Android background/terminated).
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    await ToukhVisitReminderScheduler.tryScheduleFromFcmData(
      Map<String, dynamic>.from(message.data),
    );

    // FCM already displays the system tray when a `notification` block is present.
    if (message.notification != null) return;

    final title = _nonEmpty(message.data['title']?.toString()) ?? 'Havit';
    final body = _nonEmpty(message.data['body']?.toString()) ??
        _nonEmpty(message.data['description']?.toString()) ??
        '';

    if (title.isEmpty && body.isEmpty) {
      debugPrint('FCM background: empty payload ${message.messageId}');
      return;
    }

    final plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: DarwinInitializationSettings(),
      ),
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        ToukhPushConfig.androidChannelId,
        ToukhPushConfig.androidChannelName,
        description: ToukhPushConfig.androidChannelDescription,
        importance: Importance.high,
      );
      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await plugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          ToukhPushConfig.androidChannelId,
          ToukhPushConfig.androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// Legacy handler — prefer per-app handlers with [DefaultFirebaseOptions].
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await showBackgroundNotification(message);
  }

  Future<void> initialize({
    required NotificationTapHandler onTap,
    required ToukhNotificationRecipient recipient,
    required FirebaseFirestore firestore,
    FcmTokenPersister? persistToken,
    ForegroundNotificationHandler? onForegroundNotification,
  }) async {
    if (_initialized) return;
    _persistToken = persistToken;
    _onTap = onTap;
    _onForegroundNotification = onForegroundNotification;
    _recipient = recipient;
    _firestore = firestore;

    await _local.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/${ToukhPushConfig.androidIcon}'),
        iOS: const DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _handlePayloadString(payload);
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        ToukhPushConfig.androidChannelId,
        ToukhPushConfig.androidChannelName,
        description: ToukhPushConfig.androidChannelDescription,
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    // On iOS, APNs registration only happens after permission + register.
    // Re-request when already authorized so cold starts still call
    // registerForRemoteNotifications (needed for getAPNSToken).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    try {
      final initial = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 3));
      if (initial != null) {
        await _handleRemoteMessage(initial);
      }
    } on TimeoutException {
      debugPrint('FCM getInitialMessage timed out; skipping cold-start tap.');
    }

    if (!kIsWeb) {
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        debugPrint('FCM token refreshed (${_recipient?.name})');
        final uid = _syncedUid;
        final firestore = _firestore;
        final recipient = _recipient;
        if (uid == null ||
            uid.isEmpty ||
            firestore == null ||
            recipient == null) {
          return;
        }
        // Live-read so we merge into existing devices instead of wiping them.
        await ToukhFcmTokenSync.syncOnAppOpen(
          uid: uid,
          firestore: firestore,
          recipient: recipient,
          getCurrentToken: () async => token,
        );
      });
    }

    _initialized = true;
    final pendingUid = _pendingSyncUid;
    if (pendingUid != null && pendingUid.isNotEmpty) {
      _pendingSyncUid = null;
      unawaited(syncToken(pendingUid));
    }
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() => ToukhFcmApns.getToken();

  Future<void> syncToken(
    String uid, {
    List<String> existingFcmTokens = const [],
  }) async {
    if (kIsWeb) return;
    _syncedUid = uid;
    if (!_initialized) {
      // Auth often fires before push bootstrap; retry after [initialize].
      _pendingSyncUid = uid;
      debugPrint('FCM syncToken deferred until push init (uid=$uid)');
      return;
    }

    final existing = _syncInFlight;
    if (existing != null) {
      await existing;
      return;
    }

    final future = _syncTokenBody(uid);
    _syncInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_syncInFlight, future)) {
        _syncInFlight = null;
      }
    }
  }

  Future<void> _syncTokenBody(String uid) async {
    if (_firestore != null && _recipient != null) {
      final ok = await _syncLiveWithRetries(uid);
      if (!ok) {
        debugPrint(
          'FCM syncToken: token not registered yet; will retry on resume',
        );
      }
      return;
    }

    final persist = _persistToken;
    if (persist == null) return;
    try {
      final token = await ToukhFcmApns.getToken();
      if (token != null && token.isNotEmpty) {
        await persist(uid, token);
      }
    } catch (e, st) {
      debugPrint('FCM syncToken failed: $e\n$st');
    }
  }

  Future<bool> _syncLiveWithRetries(String uid) async {
    final firestore = _firestore;
    final recipient = _recipient;
    if (firestore == null || recipient == null) return false;

    // Attempt immediately, then a couple delayed retries (APNS / permission).
    for (var i = 0; i < 3; i++) {
      if (i > 0) {
        await Future<void>.delayed(Duration(seconds: 2 * i));
      }
      try {
        final ok = await ToukhFcmTokenSync.syncOnAppOpen(
          uid: uid,
          firestore: firestore,
          recipient: recipient,
          getCurrentToken: getToken,
        );
        if (ok) return true;
      } on FirebaseException catch (e) {
        debugPrint('FCM syncLive attempt ${i + 1}: ${e.code}');
      } catch (e) {
        debugPrint('FCM syncLive attempt ${i + 1}: $e');
      }
    }
    return false;
  }

  /// Removes this device token from the signed-in profile, then clears local sync state.
  Future<void> removeDeviceTokenOnSignOut(String uid) async {
    if (kIsWeb) return;
    final firestore = _firestore;
    final recipient = _recipient;
    if (firestore != null && recipient != null && uid.isNotEmpty) {
      await ToukhFcmTokenSync.removeCurrentDeviceToken(
        uid: uid,
        firestore: firestore,
        recipient: recipient,
        getCurrentToken: getToken,
      );
    }
    if (_syncedUid == uid) {
      _syncedUid = null;
    }
    if (_pendingSyncUid == uid) {
      _pendingSyncUid = null;
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    unawaited(_showForegroundNotification(message));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    await ToukhVisitReminderScheduler.tryScheduleFromFcmData(
      Map<String, dynamic>.from(message.data),
    );

    final n = message.notification;
    final data = message.data;
    final title = _nonEmpty(n?.title) ??
        _nonEmpty(data['title']?.toString()) ??
        'Havit';
    final body = _nonEmpty(n?.body) ??
        _nonEmpty(data['body']?.toString()) ??
        _nonEmpty(data['description']?.toString()) ??
        '';

    if (title.isEmpty && body.isEmpty) {
      debugPrint('FCM foreground: empty payload ${message.messageId}');
      return;
    }

    final parsed = _notificationFromMessage(message);
    final handler = _onForegroundNotification;
    if (handler != null && parsed != null) {
      final handled = handler(parsed);
      if (handled) return;
    }

    final imageUrl = _resolveImageUrl(message);
    final fcmPayload = _encodeTapPayload(message);
    final details = await _buildForegroundNotificationDetails(imageUrl);

    await _local.show(
      message.hashCode,
      title,
      body,
      details,
      payload: fcmPayload,
    );
  }

  ToukhNotification? _notificationFromMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    if (message.notification != null) {
      data['title'] ??= message.notification!.title;
      data['body'] ??= message.notification!.body;
    }
    var notification = ToukhNotificationMapper.fromFcmData(data);
    if (notification != null) return notification;

    final orderId = data[ToukhFcmDataKeys.orderId]?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      return ToukhNotification(
        id: data[ToukhFcmDataKeys.notificationId]?.toString() ?? orderId,
        title: data['title']?.toString() ?? 'Havit',
        description:
            data['body']?.toString() ?? data['description']?.toString() ?? '',
        imageUrl: data[ToukhFcmDataKeys.imageUrl]?.toString(),
        rootRoute: data[ToukhFcmDataKeys.rootRoute]?.toString() ?? '',
        payload: _decodePayloadJson(data[ToukhFcmDataKeys.payloadJson]),
        type: data[ToukhFcmDataKeys.type]?.toString(),
        orderId: orderId,
        category: data[ToukhFcmDataKeys.category]?.toString() ?? 'order',
      );
    }

    final rideId = data['rideId']?.toString() ??
        _decodePayloadJson(data[ToukhFcmDataKeys.payloadJson])['rideId']
            ?.toString();
    if (rideId != null && rideId.isNotEmpty) {
      final payload = _decodePayloadJson(data[ToukhFcmDataKeys.payloadJson]);
      payload.putIfAbsent('rideId', () => rideId);
      return ToukhNotification(
        id: data[ToukhFcmDataKeys.notificationId]?.toString() ??
            'ride_$rideId',
        title: data['title']?.toString() ?? 'Havit',
        description:
            data['body']?.toString() ?? data['description']?.toString() ?? '',
        imageUrl: data[ToukhFcmDataKeys.imageUrl]?.toString(),
        rootRoute: data[ToukhFcmDataKeys.rootRoute]?.toString() ?? '',
        payload: payload,
        type: data[ToukhFcmDataKeys.type]?.toString(),
        category: data[ToukhFcmDataKeys.category]?.toString() ?? 'ride',
      );
    }
    return null;
  }

  Map<String, dynamic> _decodePayloadJson(dynamic raw) {
    if (raw is! String || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  String? _resolveImageUrl(RemoteMessage message) {
    final n = message.notification;
    final fromData = message.data['imageUrl'];
    if (fromData != null && fromData.trim().isNotEmpty) return fromData.trim();
    final android = n?.android?.imageUrl;
    if (android != null && android.trim().isNotEmpty) return android.trim();
    final apple = n?.apple?.imageUrl;
    if (apple != null && apple.trim().isNotEmpty) return apple.trim();
    return null;
  }

  Future<NotificationDetails> _buildForegroundNotificationDetails(
    String? imageUrl,
  ) async {
    if (imageUrl == null || imageUrl.isEmpty || kIsWeb) {
      return _defaultNotificationDetails();
    }

    final imageFile = await _downloadNotificationImage(imageUrl);
    if (imageFile == null) return _defaultNotificationDetails();

    if (defaultTargetPlatform == TargetPlatform.android) {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          ToukhPushConfig.androidChannelId,
          ToukhPushConfig.androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(imageFile.path),
            hideExpandedLargeIcon: true,
          ),
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return NotificationDetails(
        iOS: DarwinNotificationDetails(
          attachments: [DarwinNotificationAttachment(imageFile.path)],
        ),
      );
    }

    return _defaultNotificationDetails();
  }

  Future<File?> _downloadNotificationImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      final file = File(
        '${Directory.systemTemp.path}/toukh_fcm_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      debugPrint('FCM foreground image download failed: $e');
      return null;
    }
  }

  NotificationDetails _defaultNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        ToukhPushConfig.androidChannelId,
        ToukhPushConfig.androidChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<void> _onMessageOpened(RemoteMessage message) async {
    await _handleRemoteMessage(message);
  }

  Future<void> _handleRemoteMessage(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    if (message.notification != null) {
      data['title'] ??= message.notification!.title;
      data['body'] ??= message.notification!.body;
    }
    final notification = ToukhNotificationMapper.fromFcmData(data);
    if (notification != null && _onTap != null) {
      await _onTap!(notification);
    }
  }

  void _handlePayloadString(String payload) {
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final notification = ToukhNotificationMapper.fromFcmData(map);
      if (notification != null && _onTap != null) {
        _onTap!(notification);
      }
    } catch (e) {
      debugPrint('FCM tap payload parse failed: $e');
    }
  }

  String _encodeTapPayload(RemoteMessage message) {
    final data = Map<String, String>.from(message.data);
    return jsonEncode(data);
  }
}
