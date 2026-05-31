import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

/// Maps Twilio / OTP repository errors to localized snack messages.
String messageForOtpError(Object error) {
  if (error is FormatException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('session expired') || msg.contains('resend')) {
      return AppStrings.Auth.otpSessionExpired.tr;
    }
    if (msg.contains('6 digit')) {
      return AppStrings.Auth.otpInvalidCode.tr;
    }
    if (msg.contains('too short')) {
      return AppStrings.Auth.minPasswordLength.tr;
    }
    if (msg.contains('twilio') && msg.contains('not configured')) {
      return AppStrings.Auth.otpTwilioNotConfigured.tr;
    }
  }

  final raw = error.toString().toLowerCase();
  if (raw.contains('60410') ||
      raw.contains('max attempts') ||
      raw.contains('rate limit')) {
    return AppStrings.Auth.otpRateLimited.tr;
  }
  if (raw.contains('60200') ||
      raw.contains('invalid parameter') && raw.contains('to')) {
    return AppStrings.Auth.invalidPhone.tr;
  }
  if (raw.contains('unverified') ||
      raw.contains('21608') ||
      raw.contains('trial')) {
    return AppStrings.Auth.otpTrialUnverified.tr;
  }
  if (raw.contains('invalid') &&
      (raw.contains('code') || raw.contains('verification'))) {
    return AppStrings.Auth.otpInvalidCode.tr;
  }
  if (raw.contains('expired')) {
    return AppStrings.Auth.otpSessionExpired.tr;
  }

  return AppStrings.Auth.otpSendFailed.tr;
}
