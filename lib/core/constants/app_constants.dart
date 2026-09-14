import 'package:toukh_ui/toukh_ui.dart';

abstract final class AppConstants {
  AppConstants._();

  /// Firebase Auth synthetic email: `provider{phoneDigits}@toukh.com`.
  static const syntheticEmailDomain = 'toukh.com';

  /// Firestore collection for shop/service provider profiles.
  static const providersCollection = ToukhFirestoreCollections.providers;

  /// Driver profiles (courier app).
  static const driversCollection = ToukhFirestoreCollections.drivers;

  /// Driver registration applications (courier app).
  static const deliveryRequestsCollection = ToukhFirestoreCollections.deliveryRequestsOnboarding;

  static const mockOtpPhone = '0123456789';
  static const mockOtpCode = '123456';

  static const supportEmail = 'support@toukh.app';
  static const supportServicesEmail = 'toukhservices@gmail.com';
  static const deletedAccountEmailSubject = 'My Account Has Been Deleted';
  static const supportWhatsAppNumberDigits = '201050442212';
}
