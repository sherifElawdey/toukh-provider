import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/core/util/city_key.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_provider/shared/shared.dart';
import 'package:get/get.dart';

class RegisterMapScreen extends StatefulWidget {
  const RegisterMapScreen({super.key});

  @override
  State<RegisterMapScreen> createState() => _RegisterMapScreenState();
}

class _RegisterMapScreenState extends State<RegisterMapScreen> {
  GoogleMapController? _map;
  LatLng _target = const LatLng(30.0444, 31.2357);
  String _address = '';
  bool _locating = true;
  bool _hasLocationPermission = false;
  bool _inServiceArea = true;
  double _zoom = 14;
  bool _mapReady = false;
  LatLng? _lastHandledCenter;

  static const _locationTimeout = Duration(seconds: 12);
  static const _minMoveDegrees = 0.00008;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating) return;
    // Never prompt — use GPS only if already granted; otherwise keep pin / default city.
    await _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _hasLocationPermission = false;
        });
        await _handleCenterChanged(_target);
        return;
      }
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever ||
          perm == LocationPermission.unableToDetermine) {
        if (mounted) {
          setState(() {
            _locating = false;
            _hasLocationPermission = false;
          });
        }
        await _handleCenterChanged(_target);
        return;
      }
      setState(() => _locating = true);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: _locationTimeout,
        ),
      );
      if (!mounted) return;
      setState(() {
        _target = LatLng(pos.latitude, pos.longitude);
        _locating = false;
        _hasLocationPermission = true;
      });
      await _handleCenterChanged(_target);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_target, 15));
      _zoom = 15;
    } catch (_) {
      if (mounted) {
        setState(() {
          _locating = false;
          _hasLocationPermission = false;
        });
      }
      await _handleCenterChanged(_target);
    }
  }

  Future<void> _reverseGeocode(LatLng ll) async {
    try {
      final marks = await placemarkFromCoordinates(ll.latitude, ll.longitude);
      if (marks.isEmpty) return;
      final p = marks.first;
      final raw = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ];
      final parts = raw
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
      if (mounted && parts.isNotEmpty) setState(() => _address = parts);
    } catch (_) {}
  }

  Future<void> _checkServiceArea(LatLng ll) async {
    try {
      final area = await getIt<GeofenceService>().findContaining(
        lat: ll.latitude,
        lng: ll.longitude,
      );
      if (!mounted) return;
      setState(() => _inServiceArea = area != null);
    } catch (_) {
      if (mounted) setState(() => _inServiceArea = false);
    }
  }

  bool _movedEnough(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() > _minMoveDegrees ||
        (a.longitude - b.longitude).abs() > _minMoveDegrees;
  }

  Future<void> _handleCenterChanged(LatLng center) async {
    _lastHandledCenter = center;
    await _reverseGeocode(center);
    await _checkServiceArea(center);
  }

  Future<void> _onCameraIdle() async {
    if (!_mapReady || !mounted) return;
    final controller = _map;
    if (controller == null) return;
    try {
      final region = await controller.getVisibleRegion();
      final center = LatLng(
        (region.northeast.latitude + region.southwest.latitude) / 2,
        (region.northeast.longitude + region.southwest.longitude) / 2,
      );
      if (!mounted) return;
      setState(() => _target = center);
      final last = _lastHandledCenter;
      if (last != null && !_movedEnough(last, center)) return;
      await _handleCenterChanged(center);
    } catch (_) {
      if (mounted) await _handleCenterChanged(_target);
    }
  }

  Future<void> _zoomBy(double delta) async {
    final controller = _map;
    if (controller == null) return;
    final next = (_zoom + delta).clamp(3.0, 20.0);
    _zoom = next;
    await controller.animateCamera(CameraUpdate.zoomTo(next));
  }

  Widget _roundMapButton({
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(onPressed: onPressed, icon: icon),
    );
  }

  Future<void> _continue() async {
    final formattedAddress = _address.isEmpty
        ? '${_target.latitude},${_target.longitude}'
        : _address;
    final area = await getIt<GeofenceService>().findContaining(
      lat: _target.latitude,
      lng: _target.longitude,
    );
    if (!mounted) return;
    if (area == null) {
      setState(() => _inServiceArea = false);
      AppSnack.show(
        context,
        message: AppStrings.Registration.locationOutsideServiceArea.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.location,
      );
      return;
    }
    final city = await resolveUserCityKey(
      lat: _target.latitude,
      lng: _target.longitude,
      formattedAddress: formattedAddress,
    );
    if (!mounted) return;
    context.read<RegistrationCubit>().setLocation(
          lat: _target.latitude,
          lng: _target.longitude,
          formattedAddress: formattedAddress,
          city: city,
          serviceAreaId: area.id,
        );
    context.push(AppRoutes.registerHours);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom + 180;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Registration.mapTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ToukhGoogleMap(
              debugScreenName: 'register_map',
              initialCameraPosition: CameraPosition(
                target: _target,
                zoom: _zoom,
              ),
              padding: EdgeInsets.only(bottom: bottomInset),
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (c) async {
                _map = c;
                await c.animateCamera(
                  CameraUpdate.newLatLngZoom(_target, _zoom),
                );
                if (!mounted) return;
                await Future<void>.delayed(const Duration(milliseconds: 350));
                if (!mounted) return;
                setState(() => _mapReady = true);
              },
              onCameraMove: (pos) {
                _target = pos.target;
                _zoom = pos.zoom;
              },
              onCameraIdle: _onCameraIdle,
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Icon(
                  ToukhIcons.location,
                  size: 48,
                  color: ToukhMapColors.pickup,
                ),
              ),
            ),
          ),
          if (!_inServiceArea)
            Positioned(
              left: AppSizes.spaceMd,
              right: AppSizes.spaceMd,
              top: AppSizes.spaceMd,
              child: Material(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spaceMd),
                  child: Row(
                    children: [
                      Icon(ToukhIcons.location, color: scheme.onErrorContainer),
                      SizedBox(width: AppSizes.spaceSm),
                      Expanded(
                        child: CustomText(
                          AppStrings.Registration.locationOutsideServiceArea.tr,
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontSize: AppSizes.fontCaption,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: AppSizes.spaceSm,
            bottom: bottomInset + AppSizes.spaceSm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _roundMapButton(
                  onPressed: () => _zoomBy(1),
                  icon: Icon(ToukhIcons.add, color: scheme.onSurface),
                ),
                SizedBox(height: AppSizes.spaceSm),
                _roundMapButton(
                  onPressed: () => _zoomBy(-1),
                  icon: Icon(ToukhIcons.remove, color: scheme.onSurface),
                ),
                SizedBox(height: AppSizes.spaceSm),
                _roundMapButton(
                  onPressed: _locating ? null : _goToCurrentLocation,
                  icon: _locating
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        )
                      : Icon(ToukhIcons.navigation, color: scheme.onSurface),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSizes.spaceBase,
            right: AppSizes.spaceBase,
            bottom: AppSizes.spaceBase,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spaceBase),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      _address.isEmpty ? '…' : _address,
                      maxLines: 3,
                      style: const TextStyle(fontSize: AppSizes.fontBody),
                    ),
                    if (!_inServiceArea) ...[
                      SizedBox(height: AppSizes.spaceSm),
                      CustomText(
                        AppStrings.Registration.locationOutsideServiceArea.tr,
                        style: TextStyle(
                          fontSize: AppSizes.fontCaption,
                          color: scheme.error,
                          height: 1.35,
                        ),
                      ),
                    ],
                    SizedBox(height: AppSizes.spaceMd),
                    RegistrationStepNavFooter(
                      useSafeArea: false,
                      padding: EdgeInsets.zero,
                      onBack: () => context.pop(),
                      onNext: _continue,
                      nextEnabled: !_locating && _inServiceArea,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    );
  }
}
