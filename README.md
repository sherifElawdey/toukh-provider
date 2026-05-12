# Toukh Service

Flutter app for Toukh shop and service providers: registration wizard, Firebase Auth (synthetic `provider{phoneDigits}@toukh.com` emails), Firestore `providers` collection, Backblaze B2 media uploads, Bloc + GoRouter + GetIt + GetX + [`toukh_ui`](../packages/toukh_ui).

## Setup

```bash
cd toukh_provider
flutter pub get
```

Configure Firebase for your bundle IDs (see `lib/firebase_options.dart`). For Google Maps, add API keys to:

- **Android**: `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`)
- **iOS**: `ios/Runner/AppDelegate.swift` / `Info.plist` per Google Maps Flutter docs.

## Run

```bash
flutter run
```

## Analyze

```bash
dart analyze lib
```
