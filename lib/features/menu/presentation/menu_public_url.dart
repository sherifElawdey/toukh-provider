import 'package:toukh_provider/domain/entities/provider_profile.dart';

/// Host of the Hav-it website that serves public menus.
const publicSiteHost = 'havit.toukh.com';

/// Menu link for QR codes: `https://havit.toukh.com/ar/menu/?id={uid}`.
///
/// Points straight at the website's live menu page, which reads the menu
/// from Firestore in the browser, so the link works as soon as the provider
/// is active and always shows current prices — no website rebuild. It is a
/// real file on the server, so it doesn't depend on `.htaccess` rewrites
/// (the older `/m/{uid}` short link does).
String publicMenuUrl(ProviderProfile profile) {
  return Uri(
    scheme: 'https',
    host: publicSiteHost,
    path: '/ar/menu/',
    queryParameters: {'id': profile.uid},
  ).toString();
}

/// Business page link for QR codes: `https://havit.toukh.com/ar/profile/?id={uid}`.
///
/// Works for every provider type (restaurants, shops, pharmacies, home
/// services…). Like [publicMenuUrl] the website reads the profile live from
/// Firestore, so it needs no rebuild and no `.htaccess` rewrites.
String publicProfileUrl(ProviderProfile profile) {
  return Uri(
    scheme: 'https',
    host: publicSiteHost,
    path: '/ar/profile/',
    queryParameters: {'id': profile.uid},
  ).toString();
}
