/// Channel used to deliver a one-time passcode (Twilio Verify `Channel`).
enum OtpDeliveryChannel {
  whatsapp,
  sms,

  /// WhatsApp-first with automatic SMS fallback (Twilio ChannelConfiguration).
  whatsappOrSms,
}
