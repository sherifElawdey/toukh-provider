import 'package:flutter/foundation.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Holds the active foreground new-order alert for the provider shell.
class ProviderOrderAlertController extends ChangeNotifier {
  ProviderOrderAlertController._();
  static final ProviderOrderAlertController instance =
      ProviderOrderAlertController._();

  ToukhNotification? _active;

  ToukhNotification? get active => _active;

  void show(ToukhNotification notification) {
    _active = notification;
    notifyListeners();
  }

  void dismiss() {
    if (_active == null) return;
    _active = null;
    notifyListeners();
  }
}
