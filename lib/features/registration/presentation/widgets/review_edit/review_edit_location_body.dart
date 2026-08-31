import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/core/util/city_key.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditLocationBody extends StatefulWidget {
  const ReviewEditLocationBody({
    super.key,
    this.onAddressChanged,
  });

  /// Live reverse-geocoded address for the sheet footer.
  final ValueChanged<String>? onAddressChanged;

  @override
  State<ReviewEditLocationBody> createState() => ReviewEditLocationBodyState();
}

class ReviewEditLocationBodyState extends State<ReviewEditLocationBody> {
  GoogleMapController? _map;
  late LatLng _target;
  String _address = '';
  bool _locating = false;
  bool _hasLocationPermission = false;

  static const _locationTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    if (d.lat != null && d.lng != null) {
      _target = LatLng(d.lat!, d.lng!);
      // Local only — parent already seeds footer; avoid setState during mount.
      _address = d.formattedAddress;
    } else {
      _target = const LatLng(30.0444, 31.2357);
    }
    if (d.lat == null || d.lng == null) {
      _locating = true;
      _initLocation();
    } else {
      _reverseGeocode(_target);
    }
  }

  void _setAddress(String value) {
    _address = value;
    final callback = widget.onAddressChanged;
    if (callback == null) return;
    // Defer so parent setState never runs during this widget's build/mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback(value);
    });
  }

  Future<void> _initLocation() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (mounted) {
          setState(() {
            _locating = false;
            _hasLocationPermission = false;
          });
        }
        await _reverseGeocode(_target);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locating = false;
            _hasLocationPermission = false;
          });
        }
        await _reverseGeocode(_target);
        return;
      }
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
      await _reverseGeocode(_target);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_target, 15));
    } catch (_) {
      if (mounted) {
        setState(() {
          _locating = false;
          _hasLocationPermission = false;
        });
      }
      await _reverseGeocode(_target);
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
      if (mounted) {
        setState(() => _setAddress(parts));
      }
    } catch (_) {}
  }

  Future<void> _onCameraIdle() async {
    final controller = _map;
    if (controller == null || !mounted) return;
    try {
      final region = await controller.getVisibleRegion();
      final center = LatLng(
        (region.northeast.latitude + region.southwest.latitude) / 2,
        (region.northeast.longitude + region.southwest.longitude) / 2,
      );
      if (!mounted) return;
      setState(() => _target = center);
      await _reverseGeocode(center);
    } catch (_) {
      if (mounted) await _reverseGeocode(_target);
    }
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ToukhGoogleMap(
          debugScreenName: 'review_edit_location',
          initialCameraPosition: CameraPosition(
            target: _target,
            zoom: 14,
          ),
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: _hasLocationPermission,
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
          onMapCreated: (c) {
            _map = c;
            c.animateCamera(CameraUpdate.newLatLngZoom(_target, 14));
          },
          onCameraMove: (pos) => _target = pos.target,
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
