import 'package:geocoding/geocoding.dart';

/// Normalized city label for comparison (lowercase, trimmed).
String normalizeCityKey(String raw) =>
    raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String? cityKeyFromPlacemark(Placemark placemark) {
  for (final candidate in [
    placemark.locality,
    placemark.subAdministrativeArea,
    placemark.administrativeArea,
  ]) {
    if (candidate != null && candidate.trim().isNotEmpty) {
      return normalizeCityKey(candidate);
    }
  }
  return null;
}

Future<String?> cityKeyFromCoordinates(double lat, double lng) async {
  try {
    final marks = await placemarkFromCoordinates(lat, lng);
    if (marks.isEmpty) return null;
    return cityKeyFromPlacemark(marks.first);
  } catch (_) {
    return null;
  }
}

String? cityKeyFromFormattedAddress(String? formatted) {
  if (formatted == null || formatted.trim().isEmpty) return null;
  final parts = formatted
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;

  final last = parts.last.toLowerCase();
  if (parts.length >= 2 &&
      (last.contains('egypt') || last.contains('مصر') || last == 'eg')) {
    return normalizeCityKey(parts[parts.length - 2]);
  }
  if (parts.length >= 2) {
    return normalizeCityKey(parts[parts.length - 2]);
  }
  return normalizeCityKey(parts.last);
}

Future<String?> resolveUserCityKey({
  required double lat,
  required double lng,
  required String formattedAddress,
}) async {
  final fromGeo = await cityKeyFromCoordinates(lat, lng);
  if (fromGeo != null && fromGeo.isNotEmpty) return fromGeo;
  return cityKeyFromFormattedAddress(formattedAddress);
}
