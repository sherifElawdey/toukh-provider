// Seeds 12 Toukh Service provider accounts (Firebase Auth + Firestore `providers`).
//
// ## Run (from `toukh_provider/`)
//
// ```bash
// flutter pub get
// dart run tool/seed_providers.dart
// ```
//
// Logic lives in [lib/core/dev/provider_accounts_seed.dart]; this file only
// bootstraps Firebase for CLI (desktop uses Web options).
//
// ## Login (all accounts)
//
// Password for every account: `1234567890`
//
// | # | Label              | Phone digits   |
// |---|--------------------|----------------|
// | 1 | Restaurant · Nile   | 01234567891    |
// | 2 | Restaurant · Oasis  | 01234567892    |
// | 3 | Supermarket · Fresh | 01234567893    |
// | 4 | Supermarket · Metro | 01234567894    |
// | 5 | Pharmacy · Care     | 01234567895    |
// | 6 | Pharmacy · Vital    | 01234567896    |
// | 7 | Grocery · Green     | 01234567897    |
// | 8 | Grocery · Harvest   | 01234567898    |
// | 9 | Home · Cleaning     | 01234567899    |
// |10 | Home · Electrical   | 01234567900    |
// |11 | Home · Plumbing     | 01234567901    |
// |12 | Home · Beauty       | 01234567902    |
//
// ## Firestore security rules
//
// Client SDK: each account signs in before writing its own `providers/{uid}` doc.
// If rules block writes, use Firebase Admin SDK instead.

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:toukh_provider/core/dev/provider_accounts_seed.dart';
import 'package:toukh_provider/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: _firebaseOptionsForSeedRunner());

  await seedProviderAccounts(
    auth: FirebaseAuth.instance,
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
