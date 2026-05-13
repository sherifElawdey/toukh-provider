import 'package:toukh_ui/toukh_ui.dart';

/// Twilio Verify credentials from `--dart-define` (never commit real values).
///
/// ```bash
/// flutter run --dart-define=TWILIO_ACCOUNT_SID=AC... \
///   --dart-define=TWILIO_AUTH_TOKEN=... \
///   --dart-define=TWILIO_VERIFY_SERVICE_SID=VA...
/// ```
TwilioVerifyConfig twilioVerifyConfigFromEnvironment() {
  const accountSid = String.fromEnvironment('TWILIO_ACCOUNT_SID');
  const authToken = String.fromEnvironment('TWILIO_AUTH_TOKEN');
  const serviceSid = String.fromEnvironment('TWILIO_VERIFY_SERVICE_SID');
  return const TwilioVerifyConfig(
    accountSid: accountSid,
    authToken: authToken,
    serviceSid: serviceSid,
  );
}
