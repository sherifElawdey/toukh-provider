import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

/// iOS APNS token readiness before requesting FCM token.
abstract final class ToukhFcmApns {
  ToukhFcmApns._();

  /// Longer than before: APNS often arrives after the first 1–2s on cold start.
  static const _retryCount = 16;
  static const _retryDelay = Duration(milliseconds: 500);

  static Future<String?>? _inFlight;
  static bool _loggedSimulatorSkip = false;
  static bool _loggedApnsMissing = false;

  static bool get _isIos => !kIsWeb && Platform.isIOS;

  /// iOS Simulator has no reliable APNs token; skip noisy retries there.
  static bool get _isIosSimulator {
    if (!_isIos) return false;
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
        Platform.environment.containsKey('SIMULATOR_UDID') ||
        Platform.environment['SIMULATOR_HOST_HOME'] != null;
  }

  /// Waits for APNS token on iOS so [FirebaseMessaging.getToken] succeeds.
  static Future<bool> waitForApnsTokenIfNeeded() async {
    if (!_isIos) return true;
    if (_isIosSimulator) {
      if (!_loggedSimulatorSkip) {
        _loggedSimulatorSkip = true;
        debugPrint(
          'FCM: iOS Simulator — APNs unavailable; skipping FCM token fetch. '
          'Use a physical device to verify push after uploading APNs key/cert.',
        );
      }
      return false;
    }

    for (var attempt = 0; attempt < _retryCount; attempt++) {
      try {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          if (attempt > 0) {
            debugPrint('FCM APNS ready after ${attempt + 1} attempt(s)');
          }
          _loggedApnsMissing = false;
          return true;
        }
      } catch (e) {
        if (attempt == 0 || attempt == _retryCount - 1) {
          debugPrint('FCM getAPNSToken attempt ${attempt + 1}: $e');
        }
      }
      if (attempt < _retryCount - 1) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    if (!_loggedApnsMissing) {
      _loggedApnsMissing = true;
      debugPrint(
        'FCM APNS token missing after $_retryCount attempts. '
        'Check Push Notifications capability, notification permission, '
        'and that AppDelegate calls registerForRemoteNotifications().',
      );
    }
    return false;
  }

  /// Returns FCM token after APNS is ready on iOS.
  /// Concurrent callers share one in-flight attempt (avoids log storms).
  static Future<String?> getToken() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _getTokenOnce().whenComplete(() {
      _inFlight = null;
    });
    _inFlight = future;
    return future;
  }

  static Future<String?> _getTokenOnce() async {
    final apnsOk = await waitForApnsTokenIfNeeded();
    if (_isIos && !apnsOk) {
      // Never call getToken without APNS — it only throws apns-token-not-set.
      return null;
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          if (attempt > 0) {
            debugPrint('FCM getToken ok after ${attempt + 1} attempt(s)');
          }
          return token;
        }
        debugPrint('FCM getToken returned null (attempt ${attempt + 1})');
      } catch (e) {
        final message = e.toString();
        if (message.contains('apns-token-not-set')) {
          // APNS disappeared mid-flight; wait once more then bail.
          final ready = await waitForApnsTokenIfNeeded();
          if (!ready) return null;
          continue;
        }
        debugPrint('FCM getToken error (attempt ${attempt + 1}): $e');
      }
      if (attempt < 2) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    return null;
  }
}
