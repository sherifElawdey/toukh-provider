import 'dart:math';

import 'package:toukh_provider/domain/repositories/otp_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// [OtpRepository] backed by the `sendOtp` / `verifyOtp` Cloud Functions: the
/// server makes the code and texts it through ZADX (SMS).
class ZadxOtpRepository implements OtpRepository {
  ZadxOtpRepository(this._client);

  final ServerOtpClient _client;
  final Map<String, String> _tokenToE164 = {};
  static final _random = Random();

  @override
  Future<OtpRequestResult> requestOtp({required String phone}) async {
    final to = ServerOtpClient.normalizeToE164(phone);
    await PhoneRegistrationGuard.ensureAllowed(to);
    final channel = await _client.sendCode(to);
    final token =
        'otp-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}';
    _tokenToE164[token] = to;
    return OtpRequestResult(requestToken: token, channel: channel);
  }

  @override
  Future<void> verifyOtp({
    required String requestToken,
    required String code,
  }) async {
    final to = _tokenToE164[requestToken];
    if (to == null) {
      throw const FormatException('Verification session expired. Resend code.');
    }
    await _client.verifyCode(to, code);
    _tokenToE164.remove(requestToken);
  }
}
