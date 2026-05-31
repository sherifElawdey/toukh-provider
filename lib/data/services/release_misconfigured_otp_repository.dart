import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Used in release builds when Twilio dart-defines are missing.
class ReleaseMisconfiguredOtpRepository implements OtpRepository {
  static const _message =
      'Twilio Verify is not configured for this build. '
      'Pass TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and '
      'TWILIO_VERIFY_SERVICE_SID as --dart-define.';

  Never _fail() => throw const FormatException(_message);

  @override
  Future<OtpRequestResult> requestOtp({required String phone}) async {
    _fail();
  }

  @override
  Future<void> verifyOtp({
    required String requestToken,
    required String code,
  }) async {
    _fail();
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String requestToken,
    required String code,
    required String newPassword,
  }) async {
    _fail();
  }
}
