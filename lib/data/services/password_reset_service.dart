import 'package:cloud_functions/cloud_functions.dart';

/// Server-side forgot-password (functions/accounts/passwordReset.js): the code
/// is checked once by the server, which then sets the new password.
class PasswordResetService {
  PasswordResetService(this._functions);

  final FirebaseFunctions _functions;

  /// Login account kind on the server (`delivery` / `provider` / `client`).
  static const app = 'provider';

  /// Checks the WhatsApp / SMS [code]; returns a one-time reset token.
  Future<String> verifyCode({required String phone, required String code}) async {
    final res = await _functions
        .httpsCallable('verifyPasswordResetCode')
        .call<Map<String, dynamic>>({'phone': phone, 'code': code, 'app': app});
    return res.data['resetToken'] as String;
  }

  Future<void> completeReset({
    required String resetToken,
    required String newPassword,
  }) async {
    await _functions.httpsCallable('completePasswordReset').call<void>({
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }
}
