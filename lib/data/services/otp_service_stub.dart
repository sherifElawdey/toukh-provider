import 'package:flutter/foundation.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/domain/repositories/otp_repository.dart';

/// In-memory [OtpRepository] used while no real SMS provider is wired.
///
/// Behaviour (deliberately strict to match "mock OTP" expectations):
///   * `requestOtp(phone)` returns an opaque token and remembers which phone
///     it was bound to.
///   * `verifyOtp(token, code)` succeeds **only** when the phone tied to
///     `token` matches [AppConstants.mockOtpPhone] (national or Egyptian
///     E.164 digits) and `code` matches [AppConstants.mockOtpCode]. Anything
///     else throws.
///   * `resetPassword` delegates to `verifyOtp` and remains a no-op on success
///     (Firebase Auth password update would happen here in production).
class OtpServiceStub implements OtpRepository {
  final Map<String, String> _tokenToPhone = {};

  String _digits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  @override
  Future<String> requestOtp({required String phone}) async {
    debugPrint('[OtpServiceStub] requestOtp(phone=$phone)');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final token = 'stub-token-${DateTime.now().microsecondsSinceEpoch}';
    _tokenToPhone[token] = _digits(phone);
    return token;
  }

  @override
  Future<void> verifyOtp({
    required String requestToken,
    required String code,
  }) async {
    debugPrint(
      '[OtpServiceStub] verifyOtp(requestToken=$requestToken, code=$code)',
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final stored = _tokenToPhone[requestToken];
    if (stored == null) {
      throw const FormatException('Verification session expired. Resend code.');
    }
    final normalizedCode = _digits(code);
    if (normalizedCode.length != 6) {
      throw const FormatException('Code must be 6 digits.');
    }
    // Demo behaviour: accept any phone as long as the user enters
    // the configured mock code (123456).
    if (normalizedCode != AppConstants.mockOtpCode) {
      throw const FormatException('Invalid verification code.');
    }
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String requestToken,
    required String code,
    required String newPassword,
  }) async {
    debugPrint(
      '[OtpServiceStub] resetPassword(phone=$phone, code=$code, password=<hidden>)',
    );
    await verifyOtp(requestToken: requestToken, code: code);
    if (newPassword.length < 6) {
      throw const FormatException('Password is too short.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}
