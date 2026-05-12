import 'package:toukh_provider/features/auth/presentation/verify_otp_route_args.dart';

class RegistrationOtpArgsHolder {
  VerifyOtpRouteArgs? _args;

  void stashForRegistration(VerifyOtpRouteArgs args) {
    if (args.flow != VerifyOtpFlow.registerApplication) return;
    _args = args;
  }

  VerifyOtpRouteArgs? peek() => _args;

  void clear() => _args = null;
}
