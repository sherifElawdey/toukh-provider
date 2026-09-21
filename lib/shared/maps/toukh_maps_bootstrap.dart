import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

/// Android platform init so map tiles render (Hybrid Composition surface).
Future<void> initToukhMapsPlatform() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final impl = GoogleMapsFlutterPlatform.instance;
    if (impl is GoogleMapsFlutterAndroid) {
      impl.useAndroidViewSurface = true;
    }
  }
}
