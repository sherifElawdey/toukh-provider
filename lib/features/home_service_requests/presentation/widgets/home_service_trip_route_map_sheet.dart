import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

bool tripCoordsUsable(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  if (!lat.isFinite || !lng.isFinite) return false;
  if (lat == 0 && lng == 0) return false;
  return true;
}

Future<void> showTripRouteMapSheet({
  required BuildContext context,
  required double startLat,
  required double startLng,
  required double destinationLat,
  required double destinationLng,
  String? startLabel,
  String? destinationLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _TripRouteMapSheet(
      start: LatLng(startLat, startLng),
      destination: LatLng(destinationLat, destinationLng),
      startLabel: startLabel,
      destinationLabel: destinationLabel,
    ),
  );
}

class _TripRouteMapSheet extends StatelessWidget {
  const _TripRouteMapSheet({
    required this.start,
    required this.destination,
    this.startLabel,
    this.destinationLabel,
  });

  final LatLng start;
  final LatLng destination;
  final String? startLabel;
  final String? destinationLabel;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final startTitle = (startLabel ?? '').trim().isNotEmpty
        ? startLabel!.trim()
        : AppStrings.HomeServiceRequests.fieldStartLocation.tr;
    final destTitle = (destinationLabel ?? '').trim().isNotEmpty
        ? destinationLabel!.trim()
        : AppStrings.HomeServiceRequests.fieldDestination.tr;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.spaceXl,
              0,
              AppSizes.spaceXl,
              AppSizes.spaceMd,
            ),
            child: CustomText(
              AppStrings.HomeServiceRequests.viewRouteOnMap.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusMd),
              ),
              child: ToukhRouteMap(
                debugScreenName: 'provider_trip_route',
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                locateMe: () async {
                  try {
                    final pos = await Geolocator.getCurrentPosition();
                    return LatLng(pos.latitude, pos.longitude);
                  } catch (_) {
                    return null;
                  }
                },
                stops: [
                  ToukhRouteStop(
                    id: 'start',
                    position: start,
                    role: ToukhMapPinRole.provider,
                    title: startTitle,
                    service: ToukhServiceCategory.homeServices,
                  ),
                  ToukhRouteStop(
                    id: 'destination',
                    position: destination,
                    role: ToukhMapPinRole.destination,
                    title: destTitle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
