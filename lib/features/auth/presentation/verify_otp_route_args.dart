enum VerifyOtpFlow {
  passwordReset,
  registerApplication,
  providerPhoneVerification,
}

final class VerifyOtpRouteArgs {
  const VerifyOtpRouteArgs({
    required this.phone,
    required this.requestToken,
    required this.flow,
  });

  final String phone;
  final String requestToken;
  final VerifyOtpFlow flow;
}
