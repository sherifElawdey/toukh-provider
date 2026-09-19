import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/core/util/city_key.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/onboarding/presentation/widgets/permission_required_sheet.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditLocationBody extends StatefulWidget {
  const ReviewEditLocationBody({
    super.key,
    this.onAddressChanged,
    this.onInServiceAreaChanged,
  });

  /// Live reverse-geocoded address for the sheet footer.
  final ValueChanged<String>? onAddressChanged;

  /// Whether the pin is inside a supported service area.
  final ValueChanged<bool>? onInServiceAreaChanged;

  @override
  State<ReviewEditLocationBody> createState() => ReviewEditLocationBodyState();
}

class ReviewEditLocationBodyState extends State<ReviewEditLocationBody> {
  GoogleMapController? _map;
  late LatLng _target;
  String _address = '';
  bool _locating = false;
  bool _hasLocationPermission = false;
  bool _locationPermanentlyDenied = false;
  bool _locationBusy = false;
  bool _inServiceArea = true;
  double _zoom = 14;
  bool _mapReady = false;
  LatLng? _lastHandledCenter;

  static const _locationTimeout = Duration(seconds: 12);
  static const _minMoveDegrees = 0.00008; // ~9 m

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    if (d.lat != null && d.lng != null) {
      _target = LatLng(d.lat!, d.lng!);
      // Keep the saved address — do not reverse-geocode on open (APIs differ).
      _address = d.formattedAddress.trim();
      _lastHandledCenter = _target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkServiceArea(_target);
        _refreshPermissionState();
      });
    } else {
      _target = const LatLng(30.0444, 31.2357);
      _locating = true;
      _initLocation(request: false);
    }
  }

  Future<void> _refreshPermissionState() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    if (!mounted) return;
    final granted = serviceOn &&
        (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse);
    setState(() {
      _hasLocationPermission = granted;
      _locationPermanentlyDenied =
          perm == LocationPermission.deniedForever || !serviceOn;
    });
  }

  void _setAddress(String value) {
    _address = value;
    final callback = widget.onAddressChanged;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback(value);
    });
  }

  void _setInServiceArea(bool value) {
    if (_inServiceArea == value) return;
    setState(() => _inServiceArea = value);
    final callback = widget.onInServiceAreaChanged;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback(value);
    });
  }

  bool _movedEnough(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() > _minMoveDegrees ||
        (a.longitude - b.longitude).abs() > _minMoveDegrees;
  }

  Future<void> _goToCurrentLocation() async {
    if (_locating || _locationBusy) return;
    if (!_hasLocationPermission) {
      await _promptLocationPermission();
      return;
    }
    setState(() => _locating = true);
    await _initLocation(request: true);
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
        await _refreshPermissionState();
        if (_hasLocationPermission) {
          await _initLocation(request: false);
        }
      } else {
        await _initLocation(request: true);
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _initLocation({bool request = false}) async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (request) {
          await Geolocator.openLocationSettings();
        }
        if (mounted) {
          setState(() {
            _locating = false;
            _hasLocationPermission = false;
            _locationPermanentlyDenied = true;
          });
        }
        await _handleCenterChanged(_target, reverseGeocode: true);
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
        await _handleCenterChanged(_target, reverseGeocode: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: _locationTimeout,
        ),
      );
      if (!mounted) return;
      final next = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _target = next;
        _locating = false;
        _hasLocationPermission = true;
        _locationPermanentlyDenied = false;
      });
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(next, 15));
      _zoom = 15;
      await _handleCenterChanged(next, reverseGeocode: true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locating = false;
          _hasLocationPermission = false;
        });
      }
      await _handleCenterChanged(_target, reverseGeocode: true);
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
      if (!mounted || parts.isEmpty) return;
      setState(() => _setAddress(parts));
    } catch (_) {}
  }

  Future<void> _checkServiceArea(LatLng ll) async {
    if (!mounted) return;
    try {
      final area = await getIt<GeofenceService>().findContaining(
        lat: ll.latitude,
        lng: ll.longitude,
      );
      if (!mounted) return;
      _setInServiceArea(area != null);
    } catch (_) {
      if (!mounted) return;
      _setInServiceArea(false);
    }
  }

  Future<void> _handleCenterChanged(
    LatLng center, {
    required bool reverseGeocode,
  }) async {
    _lastHandledCenter = center;
    if (reverseGeocode) {
      await _reverseGeocode(center);
    }
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
      await _handleCenterChanged(center, reverseGeocode: true);
    } catch (_) {
      if (mounted) await _handleCenterChanged(_target, reverseGeocode: true);
    }
  }

  Future<void> _zoomBy(double delta) async {
    final controller = _map;
    if (controller == null) return;
    final next = (_zoom + delta).clamp(3.0, 20.0);
    _zoom = next;
    await controller.animateCamera(CameraUpdate.zoomTo(next));
  }

  Future<bool> save(RegistrationCubit cubit) async {
    final formattedAddress = _address.isEmpty
        ? '${_target.latitude},${_target.longitude}'
        : _address;
    final area = await getIt<GeofenceService>().findContaining(
      lat: _target.latitude,
      lng: _target.longitude,
    );
    if (!mounted) return false;
    if (area == null) {
      _setInServiceArea(false);
      AppSnack.show(
        context,
        message: AppStrings.Registration.locationOutsideServiceArea.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.location,
      );
      return false;
    }
    final city = await resolveUserCityKey(
      lat: _target.latitude,
      lng: _target.longitude,
      formattedAddress: formattedAddress,
    );
    cubit.setLocation(
      lat: _target.latitude,
      lng: _target.longitude,
      formattedAddress: formattedAddress,
      city: city,
      serviceAreaId: area.id,
    );
    return true;
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
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        ToukhGoogleMap(
          debugScreenName: 'review_edit_location',
          initialCameraPosition: CameraPosition(
            target: _target,
            zoom: _zoom,
          ),
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          onMapCreated: (c) async {
            _map = c;
            await c.animateCamera(
              CameraUpdate.newLatLngZoom(_target, _zoom),
            );
            if (!mounted) return;
            // Allow the settle idle to pass without rewriting the saved address.
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
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Icon(
                ToukhIcons.location,
                size: 48,
                color: ToukhMapColors.pickup,
              ),
            ),
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
          bottom: AppSizes.spaceSm,
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
        if (_locating)
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: AppSizes.spaceMd),
              child: AppLoadingMark(),
            ),
          ),
      ],
    );
  }
}
