/// An order link opened before the app can show it — a cold start on web
/// (version check on splash) or a signed-out browser (login) — e.g.
/// `/#/orders/{id}` from a HAVIT Desktop Alerts notification. Kept while
/// splash / login run, then opened once instead of home.
abstract final class PendingOrderLink {
  static final _orderDetail = RegExp(r'^/orders/[A-Za-z0-9_-]+$');
  static String? _location;

  /// Keeps [location] when it is an order detail path.
  static void remember(String location) {
    if (_orderDetail.hasMatch(location)) _location = location;
  }

  /// The kept link, once.
  static String? take() {
    final location = _location;
    _location = null;
    return location;
  }

  /// Drops the kept link once the user is on it.
  static void clearIf(String location) {
    if (_location == location) _location = null;
  }
}
