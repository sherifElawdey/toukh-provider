import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_nav_footer.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

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

  static const _locationTimeout = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    super.dispose();
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

  void _continue() {
    context.read<RegistrationCubit>().setLocation(
          lat: _target.latitude,
          lng: _target.longitude,
          formattedAddress: _address.isEmpty
              ? '${_target.latitude},${_target.longitude}'
              : _address,
        );
    context.push(AppRoutes.registerHours);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 160;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Registration.mapTitle),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _target,
                zoom: 14,
              ),
              padding: EdgeInsets.only(bottom: bottomInset),
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
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_pin, size: 48, color: AppColors.error),
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
                    SizedBox(height: AppSizes.spaceMd),
                    RegistrationStepNavFooter(
                      useSafeArea: false,
                      padding: EdgeInsets.zero,
                      onBack: () => context.pop(),
                      onNext: _continue,
                      nextEnabled: !_locating,
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
