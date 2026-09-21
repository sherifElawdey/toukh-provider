import 'dart:async';

import 'package:flutter/foundation.dart';

import 'toukh_push_messaging.dart';

/// Shared push bootstrap: optional permission request, initialize, optional timeout.
abstract final class ToukhPushBootstrap {
  ToukhPushBootstrap._();

  static Future<void> configure({
    required Future<void> Function() initialize,
    bool requestPermission = true,
    Duration? timeout = const Duration(seconds: 10),
  }) async {
    if (requestPermission) {
      await ToukhPushMessaging.instance.requestPermission();
    }
    try {
      if (timeout != null) {
        await initialize().timeout(
          timeout,
          onTimeout: () {
            debugPrint(
              'ToukhPushBootstrap.initialize timed out after '
              '${timeout.inSeconds}s; continuing without push.',
            );
          },
        );
      } else {
        await initialize();
      }
    } catch (e, st) {
      debugPrint('ToukhPushBootstrap.configure failed: $e\n$st');
    }
  }
}
