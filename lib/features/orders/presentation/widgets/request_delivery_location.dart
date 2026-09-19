import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Pickup center for driver search: business profile coords, else slice store.
Location? resolveDriverRequestPickup({
  required ProviderProfile? profile,
  Location? sliceStoreLocation,
}) {
  final lat = profile?.lat;
  final lng = profile?.lng;
  if (lat != null && lng != null) {
    return Location(
      lat: lat,
      lng: lng,
      formattedAddress: profile?.address,
      serviceAreaId: profile?.serviceAreaId,
    );
  }
  return sliceStoreLocation;
}
