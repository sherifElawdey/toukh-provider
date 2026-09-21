import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// True when `window.google.maps` is defined (Maps JS script loaded).
bool isGoogleMapsJsLoaded() {
  final google = globalContext.getProperty('google'.toJS);
  if (google.isUndefinedOrNull) return false;
  final maps = (google as JSObject).getProperty('maps'.toJS);
  return !maps.isUndefinedOrNull;
}

/// Polls until Maps JS is ready or [timeout] elapses.
Future<bool> waitForGoogleMapsJs({
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (isGoogleMapsJsLoaded()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return isGoogleMapsJsLoaded();
}
