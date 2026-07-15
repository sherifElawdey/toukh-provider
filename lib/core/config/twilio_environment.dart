import 'package:toukh_provider/core/config/twilio_local_secrets.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Twilio Verify credentials for normal runs.
///
/// Resolution order:
/// 1. `--dart-define` / `--dart-define-from-file` (CI / overrides)
/// 2. [TwilioLocalSecrets] in `twilio_local_secrets.dart` (local defaults)
///
/// Fill secrets via `bash tool/setup_dart_defines.sh`. Never use OTP stub mode.
TwilioVerifyConfig twilioVerifyConfigFromEnvironment() {
  const fromDefineSid = String.fromEnvironment('TWILIO_ACCOUNT_SID');
  const fromDefineToken = String.fromEnvironment('TWILIO_AUTH_TOKEN');
  const fromDefineService = String.fromEnvironment('TWILIO_VERIFY_SERVICE_SID');

  final accountSid = fromDefineSid.isNotEmpty
      ? fromDefineSid
      : TwilioLocalSecrets.accountSid;
  final authToken = fromDefineToken.isNotEmpty
      ? fromDefineToken
      : TwilioLocalSecrets.authToken;
  final serviceSid = fromDefineService.isNotEmpty
      ? fromDefineService
      : TwilioLocalSecrets.serviceSid;

  return TwilioVerifyConfig(
    accountSid: accountSid,
    authToken: authToken,
    serviceSid: serviceSid,
  );
}
