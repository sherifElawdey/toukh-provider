import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// When true (debug `--dart-define=TOUKH_MAPS_UNSTYLED=true`), [ToukhGoogleMap]
/// skips JSON map styling so tile auth issues are not confused with style.
const bool kToukhMapsUnstyledDebug = bool.fromEnvironment(
  'TOUKH_MAPS_UNSTYLED',
  defaultValue: false,
);

/// Debug logging when a [GoogleMap] controller is created (QA / GCP verification).
void onToukhMapCreated(String screen, GoogleMapController controller) {
  if (!kDebugMode) return;
  debugPrint('════════ Google Map [$screen] controller ready ════════');
  debugPrint('Platform: $defaultTargetPlatform (web=$kIsWeb)');
  if (kToukhMapsUnstyledDebug) {
    debugPrint('TOUKH_MAPS_UNSTYLED=true — map JSON style disabled for diagnosis.');
  }
  debugPrint(
    'If tiles stay gray, check docs/google-maps-setup.md '
    '(APIs enabled, billing, key restrictions for this app package/bundle).',
  );
  debugPrint(
    'Android: if pin shows but map is blank, search logcat for '
    '"GoogleCertificatesRslt: not allowed" — add package + debug SHA-1 to the '
    'Android Maps API key in GCP (see docs/google-maps-setup.md §3).',
  );
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    debugPrint(
      'iOS: if pin shows but map is blank/gray, check Xcode console for: '
      'API key not valid, PERMISSION_DENIED, BillingNotEnabled, '
      'API_KEY_IOS_APP_BLOCKED. Confirm AppDelegate uses the dedicated '
      '"Toukh Maps iOS" key (not Firebase), Maps SDK for iOS is enabled, and '
      'bundle ID is allowed (com.toukh.toukh | '
      'com.toukh.provider.toukhProvider | com.toukh.delivery). '
      'See docs/google-maps-setup.md §3.',
    );
  }
  if (kIsWeb) {
    debugPrint(
      'Web: open DevTools → Console for gm_authFailure / RefererNotAllowedMapError.',
    );
  }
}

/// Wraps [onMapCreated] with debug logging.
void Function(GoogleMapController) toukhMapCreatedHandler(
  String screen,
  void Function(GoogleMapController controller) onReady,
) {
  return (controller) {
    onToukhMapCreated(screen, controller);
    onReady(controller);
  };
}
