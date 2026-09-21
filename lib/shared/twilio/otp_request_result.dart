import 'package:equatable/equatable.dart';

import 'otp_delivery_channel.dart';

/// Result of requesting an OTP. [requestToken] is an opaque handle the app
/// passes to [OtpRepository.verifyOtp] (implementation maps it to `To`).
class OtpRequestResult extends Equatable {
  const OtpRequestResult({
    required this.requestToken,
    required this.channel,
  });

  final String requestToken;
  final OtpDeliveryChannel channel;

  @override
  List<Object?> get props => [requestToken, channel];
}
