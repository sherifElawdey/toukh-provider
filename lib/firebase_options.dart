// Firebase config for `toukh_provider`.
//
// Shares the Toukh Firebase project; register Android/iOS apps and run:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=toukh-b5708 --out=lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuKELex1C9aTB3-1ovOyjlEcMpj9VyVlw',
    appId: '1:919479487381:android:6fb7de347903adbef1449c',
    messagingSenderId: '919479487381',
    projectId: 'toukh-b5708',
    storageBucket: 'toukh-b5708.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAHn4HkxQFz9gU2kyRuu9rXpn5YEsXfy9E',
    appId: '1:919479487381:ios:058e2f22ce836d3bf1449c',
    messagingSenderId: '919479487381',
    projectId: 'toukh-b5708',
    storageBucket: 'toukh-b5708.firebasestorage.app',
    androidClientId: '919479487381-m6hgjmcug2bakt374sr6utm503ep5vhn.apps.googleusercontent.com',
    iosClientId: '919479487381-qi0tql34m5a02ni95s2m5j88u2e9e8ce.apps.googleusercontent.com',
    iosBundleId: 'com.toukh.provider.toukhProvider',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC51eQ97nsVL7Fv_uYlngnG7QCBSk7h3P0',
    appId: '1:919479487381:web:addf15415897f372f1449c',
    messagingSenderId: '919479487381',
    projectId: 'toukh-b5708',
    authDomain: 'toukh-b5708.firebaseapp.com',
    storageBucket: 'toukh-b5708.firebasestorage.app',
    measurementId: 'G-1DNZ36N0WM',
  );

}