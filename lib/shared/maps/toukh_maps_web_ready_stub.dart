/// Stub: non-web platforms do not need the Maps JavaScript API.
bool isGoogleMapsJsLoaded() => true;

/// Stub: always ready on non-web.
Future<bool> waitForGoogleMapsJs({
  Duration timeout = const Duration(seconds: 5),
}) async =>
    true;
