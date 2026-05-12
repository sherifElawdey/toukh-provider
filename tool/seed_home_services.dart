// Seeds the Firestore `HomeServices` collection used during provider registration
// (home-service category picker).
//
// ## Run (from `toukh_provider/`)
//
// ```bash
// flutter pub get
// dart run tool/seed_home_services.dart
// ```
//
// ## Firestore rules (registration)
//
// The app reads `HomeServices` **before** the user creates a Firebase Auth account.
// Your rules must allow that read, for example in development:
//
// ```
// match /HomeServices/{docId} {
//   allow read: if true;
//   allow write: if false; // use Admin SDK or authenticated admin in production
// }
// ```
//
// For production, prefer `allow read: if true` only for this collection if it is
// non-sensitive catalog data, or seed via Admin SDK and keep client writes disabled.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:toukh_provider/core/dev/home_services_seed.dart';
import 'package:toukh_provider/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: _firebaseOptionsForSeedRunner());

  await seedHomeServiceCategories(
    firestore: FirebaseFirestore.instance,
    onProgress: print,
  );

  print('Finished.');
}

FirebaseOptions _firebaseOptionsForSeedRunner() {
  if (Platform.isAndroid) return DefaultFirebaseOptions.android;
  if (Platform.isIOS) return DefaultFirebaseOptions.ios;
  return DefaultFirebaseOptions.web;
}
