import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditLocationBody extends StatefulWidget {
  const ReviewEditLocationBody({super.key});

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
      if (mounted) setState(() => _address = parts);
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

  bool save(RegistrationCubit cubit) {
    cubit.setLocation(
      lat: _target.latitude,
      lng: _target.longitude,
      formattedAddress: _address.isEmpty
          ? '${_target.latitude},${_target.longitude}'
          : _address,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 280,
          child: Stack(
            alignment: Alignment.center,
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
                onMapCreated: (c) {
                  _map = c;
                  c.animateCamera(CameraUpdate.newLatLngZoom(_target, 14));
                },
                onCameraMove: (pos) => _target = pos.target,
                onCameraIdle: _onCameraIdle,
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 32),
                child: Icon(ToukhIcons.location, size: 48, color: ToukhMapColors.pickup),
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
        ),
        SizedBox(height: AppSizes.spaceMd),
        CustomText(
          _address.isEmpty ? '…' : _address,
          maxLines: 3,
          style: const TextStyle(fontSize: AppSizes.fontBody),
        ),
      ],
    );
  }
}
