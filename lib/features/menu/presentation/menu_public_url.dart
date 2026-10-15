import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';

/// Public landing menu URL, matching the website's routing: stored `slug`
/// first, otherwise the generated name + short id slug; `restaurant` vs
/// `store` follows the site's `isRestaurantProvider`.
String publicMenuUrl(ProviderProfile profile) {
  final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';
  final slug = profile.slug ?? generatedProfileSlug(profile.name, profile.uid);
  final kind =
      profile.serviceType == ServiceType.restaurant || profile.isRestaurantShop
      ? 'restaurant'
      : 'store';
  return 'https://toukh.com/$locale/$kind/$slug/menu';
}

String generatedProfileSlug(String name, String docId) {
  final base = slugifyBusinessName(name);
  final shortId = docId.length >= 6
      ? docId.substring(0, 6).toLowerCase()
      : docId.toLowerCase();
  if (shortId.isEmpty) return base.isEmpty ? docId : base;
  return '$base-$shortId';
}

String slugifyBusinessName(String name) {
  final trimmed = name.trim().toLowerCase();
  if (trimmed.isEmpty) return 'business';
  final buf = StringBuffer();
  for (final code in trimmed.runes) {
    if (_isSlugChar(code)) {
      buf.writeCharCode(code);
    } else if (buf.isNotEmpty && !buf.toString().endsWith('-')) {
      buf.write('-');
    }
  }
  var out = buf.toString().replaceAll(RegExp(r'-+'), '-');
  out = out.replaceAll(RegExp(r'^-+|-+$'), '');
  if (out.isEmpty) out = 'business';
  if (out.length > 80) {
    out = out.substring(0, 80).replaceAll(RegExp(r'-$'), '');
  }
  return out;
}

bool _isSlugChar(int code) {
  if (code >= 0x30 && code <= 0x39) return true;
  if (code >= 0x61 && code <= 0x7a) return true;
  if (code >= 0x0600 && code <= 0x06ff) return true;
  return false;
}
