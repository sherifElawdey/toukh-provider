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
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        setState(() => _busy = false);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _busy = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _target = LatLng(pos.latitude, pos.longitude);
        _busy = false;
      });
      await _reverseGeocode(_target);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(_target, 15));
    } catch (_) {
      setState(() => _busy = false);
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
      setState(() => _address = parts);
    } catch (_) {}
  }

  void _continue() {
    context.read<RegistrationCubit>().setLocation(
          lat: _target.latitude,
          lng: _target.longitude,
          formattedAddress: _address.isEmpty ? '${_target.latitude},${_target.longitude}' : _address,
        );
    context.push(AppRoutes.registerHours);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Registration.mapTitle),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _target,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (c) {
              _map = c;
              if (!_busy) {
                c.animateCamera(CameraUpdate.newLatLngZoom(_target, 14));
              }
            },
            onCameraIdle: () async {
              await _reverseGeocode(_target);
            },
            onCameraMove: (pos) => _target = pos.target,
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
                      nextEnabled: !_busy,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_busy) const AppLoadingOverlay(),
        ],
      ),
    );
  }
}
