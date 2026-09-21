import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_provider/shared/shared.dart';

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

class _TripRouteMapSheet extends StatefulWidget {
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
  State<_TripRouteMapSheet> createState() => _TripRouteMapSheetState();
}

class _TripRouteMapSheetState extends State<_TripRouteMapSheet> {
  GoogleMapController? _map;

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _fitBounds() async {
    final c = _map;
    if (c == null) return;
    final a = widget.start;
    final b = widget.destination;
    final south = math.min(a.latitude, b.latitude);
    final north = math.max(a.latitude, b.latitude);
    final west = math.min(a.longitude, b.longitude);
    final east = math.max(a.longitude, b.longitude);
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          64,
        ),
      );
    } catch (_) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2),
          12,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final startTitle = (widget.startLabel ?? '').trim().isNotEmpty
        ? widget.startLabel!.trim()
        : AppStrings.HomeServiceRequests.fieldStartLocation.tr;
    final destTitle = (widget.destinationLabel ?? '').trim().isNotEmpty
        ? widget.destinationLabel!.trim()
        : AppStrings.HomeServiceRequests.fieldDestination.tr;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: widget.start,
        infoWindow: InfoWindow(title: startTitle),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destination,
        infoWindow: InfoWindow(title: destTitle),
      ),
    };
    final polylines = <Polyline>{
      ToukhMapPolyline.build(
        id: 'trip_route',
        points: [widget.start, widget.destination],
      ),
    };

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
              child: ToukhGoogleMap(
                debugScreenName: 'provider_trip_route',
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (widget.start.latitude + widget.destination.latitude) / 2,
                    (widget.start.longitude + widget.destination.longitude) / 2,
                  ),
                  zoom: 12,
                ),
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                markers: markers,
                polylines: polylines,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                onMapCreated: (controller) {
                  _map = controller;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _fitBounds();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
