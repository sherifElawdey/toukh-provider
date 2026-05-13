import 'package:toukh_ui/toukh_ui.dart';

abstract class OtpRepository {
  Future<OtpRequestResult> requestOtp({required String phone});

  Future<void> verifyOtp({
    required String requestToken,
    required String code,
  });

  /// Should call [verifyOtp] internally if not done yet.

  Future<void> resetPassword({
    required String phone,
    required String requestToken,
    required String code,
    required String newPassword,
  });
}
