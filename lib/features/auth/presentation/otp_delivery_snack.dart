import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Success snack after Twilio sends an OTP (WhatsApp vs SMS).
void showOtpSentChannelSnack(
  BuildContext context, {
  required OtpDeliveryChannel channel,
  required String phoneDisplay,
}) {
  final key = channel == OtpDeliveryChannel.whatsapp
      ? AppStrings.Auth.otpSentWhatsapp
      : AppStrings.Auth.otpSentSms;
  AppSnack.show(
    context,
    message: key.trParams({'phone': phoneDisplay}),
    state: AppSnackState.success,
    icon: channel == OtpDeliveryChannel.whatsapp
        ? ToukhIcons.chat
        : PhosphorIconsRegular.chatTeardrop,
  );
}
