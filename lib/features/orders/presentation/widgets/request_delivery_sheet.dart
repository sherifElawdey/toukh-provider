import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/domain/services/driver_matching_service.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future<Location?> showRequestDeliverySheet(
  BuildContext context, {
  Location? initialLocation,
}) {
  return showModalBottomSheet<Location>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _RequestDeliverySheet(initialLocation: initialLocation),
  );
}

Future<void> showDriverAssignedSheet(
  BuildContext context, {
  required ProviderMasterOrderRow row,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: AppSizes.screenPadding.copyWith(
          top: AppSizes.spaceLg,
          bottom: AppSizes.space2xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              AppStrings.Orders.driverAssignedTitle.tr,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: AppSizes.fontHeadline,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              AppStrings.Orders.driverAssignedBody.tr,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSizes.spaceLg),
            AppFilledButton(
              text: AppStrings.Orders.driverAssignedDone.tr,
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    },
  );
}

class _RequestDeliverySheet extends StatefulWidget {
  const _RequestDeliverySheet({this.initialLocation});

  final Location? initialLocation;

  @override
  State<_RequestDeliverySheet> createState() => _RequestDeliverySheetState();
}

class _RequestDeliverySheetState extends State<_RequestDeliverySheet> {
  GoogleMapController? _map;
  LatLng _center = const LatLng(30.0444, 31.2357);
  bool _locating = true;
  List<NearbyDriver> _nearby = const [];
  bool _loadingDrivers = false;

  static const _locationTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _initCenter();
  }

  Future<void> _initCenter() async {
    if (widget.initialLocation != null) {
      setState(() {
        _center = LatLng(
          widget.initialLocation!.lat,
          widget.initialLocation!.lng,
        );
        _locating = false;
      });
      await _refreshNearby();
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: _locationTimeout,
        ),
      );
      if (!mounted) return;
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _locating = false;
      });
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
    await _refreshNearby();
  }

  Future<void> _refreshNearby() async {
    if (!mounted) return;
    setState(() => _loadingDrivers = true);
    try {
      final drivers = await getIt<DriverMatchingService>().listNearby(
        lat: _center.latitude,
        lng: _center.longitude,
      );
      if (mounted) setState(() => _nearby = drivers);
    } catch (_) {
      if (mounted) setState(() => _nearby = const []);
    } finally {
      if (mounted) setState(() => _loadingDrivers = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.Orders.requestDeliveryTitle.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: AppSizes.fontTitle,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                CustomText(
                  AppStrings.Orders.requestDeliveryHint.tr,
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 15,
                  ),
                  onMapCreated: (c) {
                    _map = c;
                    if (!_locating) {
                      c.animateCamera(CameraUpdate.newLatLngZoom(_center, 15));
                    }
                  },
                  onCameraMove: (pos) => _center = pos.target,
                  onCameraIdle: _refreshNearby,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                ),
                Icon(ToukhIcons.location, size: 48, color: AppColors.appColor),
                if (_locating)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSizes.spaceMd),
                      child: AppLoadingMark(),
                    ),
                  ),
              ],
            ),
          ),
          if (_loadingDrivers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: AppLoadingMark()),
            )
          else if (_nearby.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: AppSizes.screenPadding,
                itemCount: _nearby.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final d = _nearby[i];
                  return Chip(
                    avatar: Icon(ToukhIcons.delivery, size: 18),
                    label: Text('${d.name} · ${d.distanceMeters}m'),
                  );
                },
              ),
            )
          else
            Padding(
              padding: AppSizes.screenPadding,
              child: CustomText(
                'No couriers within 1 km — move the map or try again.',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontSize: AppSizes.fontCaption,
                ),
              ),
            ),
          Padding(
            padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.spaceLg),
            child: AppFilledButton(
              text: AppStrings.Orders.requestDeliveryConfirm.tr,
              onTap: _locating
                  ? null
                  : () {
                      Navigator.of(context).pop(
                        Location(lat: _center.latitude, lng: _center.longitude),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}
