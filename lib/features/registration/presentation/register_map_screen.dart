import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  /// Where the map opens. Null until resolved, so the map is never built at
  /// [_fallbackTarget] only to jump to the device location a moment later.
  LatLng? _start;
  LatLng _target = _fallbackTarget;
  String _address = '';
  bool _locating = true;
  bool _hasLocationPermission = false;
  bool _locationPermanentlyDenied = false;
  bool _locationBusy = false;
  bool _checkingArea = true;
  bool _inServiceArea = true;
  double _zoom = 15;
  bool _mapReady = false;
  LatLng? _lastHandledCenter;
  int _lookupGen = 0;

  static const _fallbackTarget = LatLng(30.0444, 31.2357);
  static const _locationTimeout = Duration(seconds: 12);
  static const _freshFixAge = Duration(minutes: 2);
  static const _minMoveDegrees = 0.00008;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveStart());
  }

  /// A saved pin stays put. Otherwise the map opens on the device location,
  /// and only falls back to Cairo when no location is available.
  Future<void> _resolveStart() async {
    if (!mounted) return;
    final draft = context.read<RegistrationCubit>().state;
    final lat = draft.lat;
    final lng = draft.lng;
    LatLng start;
    if (lat != null && lng != null) {
      start = LatLng(lat, lng);
      _address = draft.formattedAddress;
    } else {
      start = await _deviceLocation(request: true) ?? _fallbackTarget;
    }
    if (!mounted) return;
    setState(() {
      _start = start;
      _target = start;
      _locating = false;
    });
    await _handleCenterChanged(start);
  }

  /// Device position, or null without service / permission / a fix.
  /// A recent last-known fix is used at once instead of waiting for GPS.
  Future<LatLng?> _deviceLocation({
    bool request = false,
    bool openSettings = false,
  }) async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (openSettings) await Geolocator.openLocationSettings();
        if (mounted) {
          setState(() {
            _hasLocationPermission = false;
            _locationPermanentlyDenied = true;
          });
        }
        return null;
      }
      var perm = await Geolocator.checkPermission();
      if (request &&
          (perm == LocationPermission.denied ||
              perm == LocationPermission.unableToDetermine)) {
        perm = await Geolocator.requestPermission();
      }
      final granted =
          perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (mounted) {
        setState(() {
          _hasLocationPermission = granted;
          _locationPermanentlyDenied = perm == LocationPermission.deniedForever;
        });
      }
      if (!granted) return null;
      if (!kIsWeb) {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null &&
            DateTime.now().difference(last.timestamp) < _freshFixAge) {
          return LatLng(last.latitude, last.longitude);
        }
      }
      final pos = await ToukhPreciseLocation.current(timeout: _locationTimeout);
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      if (kIsWeb) return null;
      try {
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? null : LatLng(last.latitude, last.longitude);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating || _locationBusy) return;
    if (!_hasLocationPermission) {
      await _promptLocationPermission();
      return;
    }
    await _moveToDeviceLocation(request: true, openSettings: true);
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
        if (granted) await _moveToDeviceLocation();
      } else {
        await _moveToDeviceLocation(request: true, openSettings: true);
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  /// Recenters on the device; the pin's address and area follow at once.
  Future<void> _moveToDeviceLocation({
    bool request = false,
    bool openSettings = false,
  }) async {
    setState(() => _locating = true);
    final here = await _deviceLocation(
      request: request,
      openSettings: openSettings,
    );
    if (!mounted) return;
    setState(() => _locating = false);
    if (here == null) return;
    _target = here;
    _zoom = 15;
    await _handleCenterChanged(here);
    await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, _zoom));
  }

  bool _lookupCurrent(int gen) => mounted && gen == _lookupGen;

  Future<void> _reverseGeocode(LatLng ll, int gen) async {
    // Always Arabic, whatever the app language.
    final address = await ToukhArabicAddress.resolve(ll.latitude, ll.longitude);
    final line = address?.formattedAddress ?? '';
    if (_lookupCurrent(gen) && line.isNotEmpty) {
      setState(() => _address = line);
    }
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
    if (!mounted || !_lookupCurrent(gen)) return;
    setState(() {
      _inServiceArea = areaId != null;
      _checkingArea = false;
    });
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

  /// The address and the service area follow the pin; a newer move cancels
  /// an older lookup.
  Future<void> _handleCenterChanged(LatLng center) async {
    final gen = ++_lookupGen;
    _lastHandledCenter = center;
    if (mounted) setState(() => _checkingArea = true);
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
    ServiceArea? area;
    try {
      area = await getIt<GeofenceService>().findContaining(
        lat: point.latitude,
        lng: point.longitude,
      );
    } catch (_) {
      area = null;
    }
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
          if (_start != null)
            Positioned.fill(
              child: ToukhGoogleMap(
                key: _mapKey,
                debugScreenName: 'register_map',
                initialCameraPosition: CameraPosition(
                  target: _start!,
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
                  // Already on [_start]; wait for layout before reading the pin.
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
          if (_start != null)
            IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Center(child: _RegisterMapPin(pinKey: _pinKey)),
              ),
            ),
          if (!_hasLocationPermission && _start != null)
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
          if (!_inServiceArea && !_checkingArea)
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
                    if (!_inServiceArea && !_checkingArea) ...[
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
                      nextEnabled:
                          _start != null &&
                          !_locating &&
                          !_checkingArea &&
                          _inServiceArea,
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
