abstract class OtpRepository {
  Future<String> requestOtp({required String phone});

  Future<void> verifyOtp({
    required String requestToken,
    required String code,
  });

  Future<void> resetPassword({
    required String phone,
    required String requestToken,
    required String code,
    required String newPassword,
  });
}
