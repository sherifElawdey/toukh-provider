import 'package:toukh_provider/domain/entities/provider_profile.dart';

/// Host of the Hav-it website that serves public menus.
const publicSiteHost = 'havit.toukh.com';

/// Short menu link for QR codes: `https://havit.toukh.com/m/{uid}`.
///
/// The website redirects it to its live menu page (`/{ar|en}/menu/?id=`) in
/// the scanning phone's language and reads the menu from Firestore in the
/// browser, so the link works as soon as the provider is active and always
/// shows current prices — no website rebuild.
String publicMenuUrl(ProviderProfile profile) {
  return Uri(
    scheme: 'https',
    host: publicSiteHost,
    pathSegments: ['m', profile.uid],
  ).toString();
}
