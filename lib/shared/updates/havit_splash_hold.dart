import 'dart:async';

import 'package:flutter/foundation.dart';

/// Minimum splash visibility hold started from each app's splash [initState].
class HavitSplashHold extends ChangeNotifier {
  HavitSplashHold._();

  static final HavitSplashHold instance = HavitSplashHold._();

  static const Duration minDuration = Duration(seconds: 4);

  bool _started = false;
  bool _elapsed = false;
  Completer<void>? _completer;

  bool get elapsed => _elapsed;

  /// Starts the 4s hold once per app launch. Safe to call repeatedly.
  void start() {
    if (_started) return;
    _started = true;
    _completer = Completer<void>();
    Future<void>.delayed(minDuration, () {
      _elapsed = true;
      if (_completer != null && !_completer!.isCompleted) {
        _completer!.complete();
      }
      notifyListeners();
    });
  }

  /// Completes when [elapsed] is true (starts the hold if needed).
  Future<void> waitUntilElapsed() {
    start();
    if (_elapsed) return Future<void>.value();
    return _completer!.future;
  }
}
