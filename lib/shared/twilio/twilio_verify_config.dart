import 'package:equatable/equatable.dart';

/// Credentials for [TwilioVerifyClient]. Never hardcode in source; inject from
/// `--dart-define` or secure storage at app startup.
class TwilioVerifyConfig extends Equatable {
  const TwilioVerifyConfig({
    required this.accountSid,
    required this.authToken,
    required this.serviceSid,
  });

  final String accountSid;
  final String authToken;
  final String serviceSid;

  bool get isComplete =>
      accountSid.isNotEmpty &&
      authToken.isNotEmpty &&
      serviceSid.isNotEmpty;

  @override
  List<Object?> get props => [accountSid, authToken, serviceSid];
}
