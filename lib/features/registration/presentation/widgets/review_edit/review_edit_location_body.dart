import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/core/util/city_key.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/onboarding/presentation/widgets/permission_required_sheet.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/map_pin_lat_lng.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/store_location_gate.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditLocationBody extends StatefulWidget {
  const ReviewEditLocationBody({
    super.key,
    this.onAddressChanged,
    this.onInServiceAreaChanged,
    this.onLocatedChanged,
  });

  /// Whether there is a pin yet (a saved one, or the device position).
  /// Saving waits for it.
  final ValueChanged<bool>? onLocatedChanged;

  /// Live reverse-geocoded address for the sheet footer.
  final ValueChanged<String>? onAddressChanged;

  /// Whether the pin is inside a supported service area.
  final ValueChanged<bool>? onInServiceAreaChanged;

  @override
  State<ReviewEditLocationBody> createState() => ReviewEditLocationBodyState();
}

class ReviewEditLocationBodyState extends State<ReviewEditLocationBody> {
  final _mapKey = GlobalKey();
  final _pinKey = GlobalKey();
  GoogleMapController? _map;

  /// Null until there is a saved pin or a device fix; no made-up start.
  LatLng? _start;
  late LatLng _target;
  ToukhLocationFailure? _failure;
  String _address = '';
  bool _locating = false;
  bool _hasLocationPermission = false;
  bool _locationPermanentlyDenied = false;
  bool _locationBusy = false;
  bool _inServiceArea = true;
  double _zoom = 14;
  bool _mapReady = false;
  LatLng? _lastHandledCenter;
  int _lookupGen = 0;

  static const _locationTimeout = Duration(seconds: 12);
  static const _minMoveDegrees = 0.00008; // ~9 m

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    if (d.lat != null && d.lng != null) {
      _target = LatLng(d.lat!, d.lng!);
      _start = _target;
      // Keep the saved address — do not reverse-geocode on open (APIs differ).
      _address = d.formattedAddress.trim();
      _lastHandledCenter = _target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _checkServiceArea(_target, ++_lookupGen);
        _refreshPermissionState();
      });
    } else {
      _locating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onLocatedChanged?.call(false);
        _locateStart();
      });
    }
  }

  /// First fix when there is no saved pin; on failure the gate says why.
  Future<void> _locateStart({bool openServiceSettings = false}) async {
    setState(() {
      _locating = true;
      _failure = null;
    });
    final fix = await ToukhLocationFix.acquire(
      openServiceSettings: openServiceSettings,
      timeout: _locationTimeout,
    );
    if (!mounted) return;
    if (!fix.found) {
      setState(() {
        _locating = false;
        _failure = fix.failure;
      });
      return;
    }
    final here = LatLng(fix.lat!, fix.lng!);
    setState(() {
      _locating = false;
      _hasLocationPermission = true;
      _locationPermanentlyDenied = false;
      _start = here;
      _target = here;
      _zoom = 15;
    });
    widget.onLocatedChanged?.call(true);
    await _handleCenterChanged(here, reverseGeocode: true);
  }

  Future<void> _onGateAction() async {
    if (_locationBusy) return;
    setState(() => _locationBusy = true);
    try {
      if (_failure == ToukhLocationFailure.deniedForever) {
        await openAppSettings();
        // Coming back from Settings: try again with whatever was granted.
        await _locateStart();
      } else {
        await _locateStart(
          openServiceSettings: _failure == ToukhLocationFailure.serviceOff,
        );
      }
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  Future<void> _refreshPermissionState() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    if (!mounted) return;
    final granted =
        serviceOn &&
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
      if (!mounted) return;
      setState(() {
        _locating = true;
        _hasLocationPermission = true;
        _locationPermanentlyDenied = false;
      });
      final pos = await ToukhPreciseLocation.current(timeout: _locationTimeout);
      if (!mounted) return;
      final next = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _target = next;
        _locating = false;
      });
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(next, 15));
      _zoom = 15;
      await _handleCenterChanged(next, reverseGeocode: true);
    } catch (_) {
      // No fix: the pin stays where it is.
      if (!mounted) return;
      setState(() => _locating = false);
      AppSnack.show(
        context,
        message: AppStrings.Permissions.locationFailedSnack.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.location,
      );
    }
  }

  bool _lookupCurrent(int gen) => mounted && gen == _lookupGen;

  Future<void> _reverseGeocode(LatLng ll, int gen) async {
    // Always Arabic, whatever the app language.
    final address = await ToukhArabicAddress.resolve(ll.latitude, ll.longitude);
    final line = address?.formattedAddress ?? '';
    if (_lookupCurrent(gen) && line.isNotEmpty) {
      setState(() => _setAddress(line));
    }
  }

  Future<void> _checkServiceArea(LatLng ll, int gen) async {
    if (!_lookupCurrent(gen)) return;
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
    _setInServiceArea(areaId != null);
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

  Future<void> _handleCenterChanged(
    LatLng center, {
    required bool reverseGeocode,
  }) async {
    final gen = ++_lookupGen;
    _lastHandledCenter = center;
    if (reverseGeocode) {
      await _reverseGeocode(center, gen);
    }
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
    await _handleCenterChanged(center, reverseGeocode: true);
  }

  Future<void> _zoomBy(double delta) async {
    final controller = _map;
    if (controller == null) return;
    final next = (_zoom + delta).clamp(3.0, 20.0);
    _zoom = next;
    await controller.animateCamera(CameraUpdate.zoomTo(next));
  }

  Future<bool> save(RegistrationCubit cubit) async {
    if (_start == null) return false;
    ++_lookupGen;
    final point = await _resolvePin();
    if (!mounted) return false;
    final formattedAddress = _address.isEmpty
        ? '${point.latitude},${point.longitude}'
        : _address;
    final area = await getIt<GeofenceService>().findContaining(
      lat: point.latitude,
      lng: point.longitude,
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
      lat: point.latitude,
      lng: point.longitude,
      formattedAddress: formattedAddress,
    );
    cubit.setLocation(
      lat: point.latitude,
      lng: point.longitude,
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
      child: IconButton(onPressed: onPressed, icon: icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_start == null) {
      return ColoredBox(
        color: scheme.surface,
        child: StoreLocationGate(
          locating: _locating,
          failure: _failure,
          onAction: _locationBusy ? null : _onGateAction,
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: ToukhGoogleMap(
          key: _mapKey,
          debugScreenName: 'review_edit_location',
          initialCameraPosition: CameraPosition(target: _target, zoom: _zoom),
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
            await c.animateCamera(CameraUpdate.newLatLngZoom(_target, _zoom));
            if (!mounted) return;
            // Allow the settle idle to pass without rewriting the saved address.
            await Future<void>.delayed(const Duration(milliseconds: 350));
            if (!mounted) return;
            setState(() => _mapReady = true);
            final center = await _resolvePin();
            if (!mounted) return;
            final last = _lastHandledCenter;
            if (last != null && !_movedEnough(last, center)) return;
            await _handleCenterChanged(center, reverseGeocode: false);
          },
          onCameraMove: (pos) {
            _target = pos.target;
            _zoom = pos.zoom;
          },
          onCameraIdle: _onCameraIdle,
          ),
        ),
        IgnorePointer(
          child: Center(child: _ReviewMapPin(pinKey: _pinKey)),
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

/// Pin tip sits on the camera target.
class _ReviewMapPin extends StatelessWidget {
  const _ReviewMapPin({required this.pinKey});

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
