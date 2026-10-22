import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/core/util/city_key.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/onboarding/presentation/widgets/permission_required_sheet.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/map_pin_lat_lng.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:get/get.dart';

class RegisterMapScreen extends StatefulWidget {
  const RegisterMapScreen({
    super.key,
    this.nextRoute = AppRoutes.registerHours,
  });

  /// Pushed once the pin is inside a service area.
  final String nextRoute;

  @override
  State<RegisterMapScreen> createState() => _RegisterMapScreenState();
}

class _RegisterMapScreenState extends State<RegisterMapScreen> {
  final _mapKey = GlobalKey();
  final _pinKey = GlobalKey();
  GoogleMapController? _map;
  LatLng _target = const LatLng(30.0444, 31.2357);
  String _address = '';
  bool _locating = true;
  bool _hasLocationPermission = false;
  bool _locationPermanentlyDenied = false;
  bool _locationBusy = false;
  bool _inServiceArea = true;
  double _zoom = 14;
  bool _mapReady = false;
  LatLng? _lastHandledCenter;
  int _lookupGen = 0;

  static const _locationTimeout = Duration(seconds: 12);
  static const _minMoveDegrees = 0.00008;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAtLocation());
  }

  /// A saved pin stays put. Otherwise the map opens on the device location.
  Future<void> _startAtLocation() async {
    if (!mounted) return;
    final draft = context.read<RegistrationCubit>().state;
    final lat = draft.lat;
    final lng = draft.lng;
    if (lat != null && lng != null) {
      setState(() {
        _target = LatLng(lat, lng);
        _locating = false;
      });
      _zoom = 15;
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_target, _zoom));
      if (!mounted) return;
      await _handleCenterChanged(_target);
      return;
    }
    await _initLocation(request: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating || _locationBusy) return;
    if (!_hasLocationPermission) {
      await _promptLocationPermission();
      return;
    }
    await _initLocation(request: true, openSettings: true);
  }

  Future<void> _promptLocationPermission() async {
    if (_locationBusy) return;
    final enable = await PermissionRequiredSheet.showForLocation(
      context,
      permanentlyDenied: _locationPermanentlyDenied,
    );
    if (!enable || !mounted) return;
    await _onLocationPermissionAction();
  }

  Future<void> _onLocationPermissionAction() async {
    if (_locationBusy) return;
    setState(() => _locationBusy = true);
    try {
      if (_locationPermanentlyDenied) {
        await openAppSettings();
        final perm = await Geolocator.checkPermission();
        if (!mounted) return;
        final granted =
            perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse;
        setState(() {
          _hasLocationPermission = granted;
          _locationPermanentlyDenied = perm == LocationPermission.deniedForever;
        });
        if (granted) await _initLocation(request: false);
      } else {
        await _initLocation(request: true, openSettings: true);
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _initLocation({
    bool request = false,
    bool openSettings = false,
  }) async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (openSettings) {
          await Geolocator.openLocationSettings();
        }
        if (!mounted) return;
        setState(() {
          _locating = false;
          _hasLocationPermission = false;
          _locationPermanentlyDenied = true;
        });
        await _handleCenterChanged(_target);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (request &&
          (perm == LocationPermission.denied ||
              perm == LocationPermission.unableToDetermine)) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever ||
          perm == LocationPermission.unableToDetermine) {
        if (mounted) {
          setState(() {
            _locating = false;
            _hasLocationPermission = false;
            _locationPermanentlyDenied =
                perm == LocationPermission.deniedForever;
          });
        }
        await _handleCenterChanged(_target);
        return;
      }
      if (!mounted) return;
      setState(() {
        _locating = true;
        _hasLocationPermission = true;
        _locationPermanentlyDenied = false;
      });
      if (!kIsWeb) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null && mounted) {
          setState(() => _target = LatLng(last.latitude, last.longitude));
          await _map?.animateCamera(CameraUpdate.newLatLngZoom(_target, 15));
          _zoom = 15;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: _locationTimeout),
      );
      if (!mounted) return;
      setState(() {
        _target = LatLng(pos.latitude, pos.longitude);
        _locating = false;
      });
      await _handleCenterChanged(_target);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_target, 15));
      _zoom = 15;
    } catch (_) {
      if (mounted) {
        setState(() => _locating = false);
      }
      await _handleCenterChanged(_target);
    }
  }

  bool _lookupCurrent(int gen) => mounted && gen == _lookupGen;

  Future<void> _reverseGeocode(LatLng ll, int gen) async {
    try {
      final marks = await placemarkFromCoordinates(ll.latitude, ll.longitude);
      if (marks.isEmpty || !_lookupCurrent(gen)) return;
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
      if (_lookupCurrent(gen) && parts.isNotEmpty) {
        setState(() => _address = parts);
      }
    } catch (_) {}
  }

  Future<void> _checkServiceArea(LatLng ll, int gen) async {
    String? areaId;
    try {
      final area = await getIt<GeofenceService>().findContaining(
        lat: ll.latitude,
        lng: ll.longitude,
      );
      areaId = area?.id;
    } catch (_) {
      areaId = null;
    }
    if (!mounted || gen != _lookupGen) return;
    setState(() => _inServiceArea = areaId != null);
    final draft = context.read<RegistrationCubit>().state;
    final address = _address.trim().isNotEmpty
        ? _address.trim()
        : draft.formattedAddress;
    context.read<RegistrationCubit>().setLocation(
      lat: ll.latitude,
      lng: ll.longitude,
      formattedAddress: address,
      city: draft.city,
      serviceAreaId: areaId,
    );
  }

  bool _movedEnough(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() > _minMoveDegrees ||
        (a.longitude - b.longitude).abs() > _minMoveDegrees;
  }

  Future<void> _handleCenterChanged(LatLng center) async {
    final gen = ++_lookupGen;
    _lastHandledCenter = center;
    await _reverseGeocode(center, gen);
    if (!_lookupCurrent(gen)) return;
    await _checkServiceArea(center, gen);
  }

  Future<LatLng> _resolvePin() async {
    try {
      final point = await latLngAtPinTip(
        controller: _map,
        pinKey: _pinKey,
        mapKey: _mapKey,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
      if (point != null) {
        _target = point;
        return point;
      }
    } catch (_) {}
    return _target;
  }

  Future<void> _onCameraIdle() async {
    if (!_mapReady || !mounted) return;
    final center = await _resolvePin();
    if (!mounted) return;
    final last = _lastHandledCenter;
    if (last != null && !_movedEnough(last, center)) return;
    await _handleCenterChanged(center);
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
    ++_lookupGen;
    final point = await _resolvePin();
    if (!mounted) return;
    final formattedAddress = _address.isEmpty
        ? '${point.latitude},${point.longitude}'
        : _address;
    final area = await getIt<GeofenceService>().findContaining(
      lat: point.latitude,
      lng: point.longitude,
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
      lat: point.latitude,
      lng: point.longitude,
      formattedAddress: formattedAddress,
    );
    if (!mounted) return;
    context.read<RegistrationCubit>().setLocation(
      lat: point.latitude,
      lng: point.longitude,
      formattedAddress: formattedAddress,
      city: city,
      serviceAreaId: area.id,
    );
    context.push(widget.nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom + 270;
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
              key: _mapKey,
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
                await _onCameraIdle();
              },
              onCameraMove: (pos) {
                _target = pos.target;
                _zoom = pos.zoom;
              },
              onCameraIdle: _onCameraIdle,
            ),
          ),
          IgnorePointer(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Center(child: _RegisterMapPin(pinKey: _pinKey)),
            ),
          ),
          if (!_hasLocationPermission)
            Positioned(
              left: AppSizes.spaceMd,
              right: AppSizes.spaceMd,
              top: AppSizes.spaceMd,
              child: LocationPermissionTile(
                compact: true,
                title: AppStrings.Permissions.locationNeededTitle.tr,
                message: AppStrings.Permissions.locationNeededBody.tr,
                actionLabel: _locationPermanentlyDenied
                    ? AppStrings.Permissions.openSettings.tr
                    : AppStrings.Permissions.allowLocation.tr,
                busy: _locationBusy || _locating,
                onAction: _promptLocationPermission,
              ),
            ),
          if (!_inServiceArea)
            Positioned(
              left: AppSizes.spaceMd,
              right: AppSizes.spaceMd,
              top: _hasLocationPermission
                  ? AppSizes.spaceMd
                  : AppSizes.spaceMd + 88,
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
                    const RegistrationStageProgress(
                      stage: RegistrationStage.place,
                    ),
                    SizedBox(height: AppSizes.spaceMd),
                    Row(
                      children: [
                        const RegistrationIllustration(
                          icon: PhosphorIconsDuotone.mapPinLine,
                          size: 44,
                        ),
                        SizedBox(width: AppSizes.spaceMd),
                        Expanded(
                          child: CustomText(
                            AppStrings.Registration.mapHint,
                            style: TextStyle(
                              fontSize: AppSizes.fontCaption,
                              height: 1.4,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceMd),
                    CustomText(
                      _address.isEmpty ? '…' : _address,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: AppSizes.fontBody,
                        fontWeight: FontWeight.w700,
                      ),
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

/// Pin tip sits on the map's padded camera target.
class _RegisterMapPin extends StatelessWidget {
  const _RegisterMapPin({required this.pinKey});

  final GlobalKey pinKey;
  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -_size / 2),
      child: Icon(
        key: pinKey,
        ToukhIcons.location,
        size: _size,
        color: ToukhMapColors.pickup,
      ),
    );
  }
}
