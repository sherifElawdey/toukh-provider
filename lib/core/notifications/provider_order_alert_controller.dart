import 'package:flutter/foundation.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Holds the active foreground new-order alert for the provider shell.
class ProviderOrderAlertController extends ChangeNotifier {
  ProviderOrderAlertController._();
  static final ProviderOrderAlertController instance =
      ProviderOrderAlertController._();

  ToukhNotification? _active;
  final Set<String> _shownOrderIds = {};

  ToukhNotification? get active => _active;

  void show(ToukhNotification notification) {
    final orderId = notification.orderId ??
        notification.payload['orderId']?.toString() ??
        '';
    if (orderId.isNotEmpty) {
      if (_shownOrderIds.contains(orderId)) return;
      _shownOrderIds.add(orderId);
    }

    _active = notification;
    notifyListeners();
  }

  void dismiss() {
    if (_active == null) return;
    _active = null;
    notifyListeners();
  }
}
