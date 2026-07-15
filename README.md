# Toukh Service

Flutter app for Toukh shop and service providers: registration wizard, Firebase Auth (synthetic `provider{phoneDigits}@toukh.com` emails), Firestore `providers` collection, Backblaze B2 media uploads, Bloc + GoRouter + GetIt + GetX + [`toukh_ui`](../packages/toukh_ui).

## Setup

```bash
cd toukh_provider
flutter pub get
```
toukh_ui:
git:
url: https://github.com/sherifElawdey/toukh-ui-constants.git

Configure Firebase for your bundle IDs (see `lib/firebase_options.dart`). For Google Maps, add API keys to:

- **Android**: `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`)
- **iOS**: `ios/Runner/AppDelegate.swift` / `Info.plist` per Google Maps Flutter docs.

## Run

```bash
flutter run
```

Without Twilio dart-defines (and without `twilio_local_secrets.dart`), OTP is not available.

## OTP (Twilio Verify)

Registration, account phone verification, and forgot-password **send / verify / resend** use [Twilio Verify v2](https://www.twilio.com/docs/verify/api) when all three build-time defines are set. Implementation: `TwilioVerifyOtpRepository` + `TwilioVerifyClient` in [`packages/toukh_ui`](../packages/toukh_ui/README.md).

### One-time setup (debug + release)

```bash
cd toukh_provider
bash tool/setup_dart_defines.sh
# Edit secrets/dart_defines.json, re-run script → writes twilio_local_secrets.dart
flutter run   # no dart-define needed — real Twilio OTP always
```

There is **no OTP stub mode**. Missing credentials → configuration error.

Live smoke (from `toukh/`):

```bash
dart run tool/test_twilio_otp.dart --to=+2010XXXXXXXX
```

### Twilio Console (one-time)

1. Sign up at [twilio.com/try-twilio](https://www.twilio.com/try-twilio).
2. Copy **Account SID** and **Auth Token** from [API keys & tokens](https://console.twilio.com/us1/account/keys-credentials/api-keys).
3. Create a **Verify Service** ([Verify → Services](https://console.twilio.com/us1/verify/services)) and copy the Service SID (`VA…`).
4. **Trial**: add each test handset under [Verified Caller IDs](https://console.twilio.com/us1/develop/phone-numbers/verified-caller-ids).
5. **Geo**: allow **Egypt (+20)** for SMS/WhatsApp in Verify/Messaging geo settings.
6. **WhatsApp**: attach a WhatsApp sender to the Verify Service (BYO). The app sends WhatsApp-first with SMS fallback; without a sender, SMS retry still works.

Never commit credentials. Rotate the Auth Token if it was ever exposed.

Release builds without credentials **fail OTP** with a clear error. Full checklist: [`../toukh/docs/twilio-otp-setup.md`](../toukh/docs/twilio-otp-setup.md).

### How to tell Twilio is active

- Debug log prints `Twilio Verify configured — real OTP (WhatsApp/SMS).`
- After sending a code, the snack mentions **WhatsApp** or **SMS**.

### Forgot password limitation

OTP send/verify/resend is real with Twilio. **Setting a new Firebase password** after OTP is not implemented on the client (synthetic email accounts need Admin SDK). Users can verify OTP and reach the reset screen, but password change requires a follow-up Cloud Function. Registration and `phoneVerified` in Firestore are fully supported.

### Manual test checklist

| Flow | Expected |
|------|----------|
| Registration → review → send code | WhatsApp or SMS; 6-digit code from Twilio |
| Verify OTP → submit | `phoneVerified: true` → request submitted |
| Resend | After 60s, up to 2 resends; 90s cooldown after first resend |
| Account verify phone | Same send/verify path → splash |
| Forgot password | OTP send/verify; reset screen verifies once with Twilio |
| Missing credentials | OTP errors with “not configured” message |

## Analyze

```bash
dart analyze lib
```
