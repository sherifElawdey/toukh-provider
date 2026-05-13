import 'dart:math';

import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// [OtpRepository] backed by Twilio Verify v2 (WhatsApp-first + SMS fallback).
class TwilioVerifyOtpRepository implements OtpRepository {
  TwilioVerifyOtpRepository(this._client);

  final TwilioVerifyClient _client;
  final Map<String, String> _tokenToE164 = {};
  static final _random = Random();

  @override
  Future<OtpRequestResult> requestOtp({required String phone}) async {
    final to = TwilioVerifyClient.normalizeToE164(phone);
    final send = await _client.sendVerification(to);
    final token =
        'otp-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}';
    _tokenToE164[token] = to;
    return OtpRequestResult(requestToken: token, channel: send.channel);
  }

  @override
  Future<void> verifyOtp({
    required String requestToken,
    required String code,
  }) async {
    final to = _tokenToE164[requestToken];
    if (to == null) {
      throw const FormatException(
        'Verification session expired. Resend code.',
      );
    }
    await _client.checkVerification(to, code);
    _tokenToE164.remove(requestToken);
  }

  @override
  Future<void> resetPassword({
    required String phone,
    required String requestToken,
    required String code,
    required String newPassword,
  }) async {
    await verifyOtp(requestToken: requestToken, code: code);
    if (newPassword.length < 6) {
      throw const FormatException('Password is too short.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
