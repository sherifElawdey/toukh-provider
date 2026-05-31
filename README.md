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

Without Twilio dart-defines (debug only), OTP uses `OtpServiceStub` with code `123456`.

## OTP (Twilio Verify)

Registration, account phone verification, and forgot-password **send / verify / resend** use [Twilio Verify v2](https://www.twilio.com/docs/verify/api) when all three build-time defines are set. Implementation: `TwilioVerifyOtpRepository` + `TwilioVerifyClient` in [`packages/toukh_ui`](../packages/toukh_ui/README.md).

### Twilio Console (one-time)

1. Sign up at [twilio.com/try-twilio](https://www.twilio.com/try-twilio).
2. Copy **Account SID** and **Auth Token** from [API keys & tokens](https://console.twilio.com/us1/account/keys-credentials/api-keys).
3. Create a **Verify Service** ([Verify → Services](https://console.twilio.com/us1/verify/services)) and copy the Service SID (`VA…`).
4. **Trial**: add each test handset under [Verified Caller IDs](https://console.twilio.com/us1/develop/phone-numbers/verified-caller-ids).
5. **Geo**: allow **Egypt (+20)** for SMS/WhatsApp in Verify/Messaging geo settings.
6. Optional: enable WhatsApp on the Verify service for WhatsApp-first delivery (app falls back to SMS automatically).

Never commit credentials. Rotate the Auth Token if it was ever exposed.

### Run / build with real OTP

```bash
cd toukh_provider
flutter run \
  --dart-define=TWILIO_ACCOUNT_SID=ACxxxxxxxx \
  --dart-define=TWILIO_AUTH_TOKEN=xxxxxxxx \
  --dart-define=TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxx
```

Release builds (`flutter build apk` / `ipa`) must pass the same defines (e.g. CI secrets). **Release without defines fails OTP** with a clear error instead of the dev stub.

Local helper (optional):

```bash
cp tool/run_with_twilio.sh.example tool/run_with_twilio.sh
# Edit run_with_twilio.sh with your SIDs, then:
./tool/run_with_twilio.sh
```

### How to tell Twilio is active

- Debug log does **not** print `using OtpServiceStub`.
- After sending a code, the snack mentions **WhatsApp** or **SMS** (not only a generic message).
- Codes are **not** `123456` unless you are on the stub.

### Forgot password limitation

OTP send/verify/resend is real with Twilio. **Setting a new Firebase password** after OTP is not implemented on the client (synthetic email accounts need Admin SDK). Users can verify OTP and reach the reset screen, but password change requires a follow-up Cloud Function. Registration and `phoneVerified` in Firestore are fully supported.

### Manual test checklist

| Flow | Expected with Twilio defines |
|------|------------------------------|
| Registration → review → send code | WhatsApp or SMS; 6-digit code from Twilio |
| Verify OTP → submit | `phoneVerified: true` → request submitted |
| Resend | After 60s, up to 2 resends; 90s cooldown after first resend |
| Account verify phone | Same send/verify path → splash |
| Forgot password | OTP send/verify; reset screen verifies once with Twilio |
| Debug without defines | Stub code `123456` |
| Release without defines | OTP errors with “not configured” message |

## Analyze

```bash
dart analyze lib
```
