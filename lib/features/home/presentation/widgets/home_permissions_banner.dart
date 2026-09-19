import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Home soft-gate banner when notification or location is still denied.
class HomePermissionsBanner extends StatefulWidget {
  const HomePermissionsBanner({super.key});

  @override
  State<HomePermissionsBanner> createState() => _HomePermissionsBannerState();
}

class _HomePermissionsBannerState extends State<HomePermissionsBanner>
    with WidgetsBindingObserver {
  bool _needNotif = false;
  bool _needLocation = false;
  bool _notifPermanentlyDenied = false;
  bool _locationPermanentlyDenied = false;
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_sync());
  }

  Future<void> _sync() async {
    final cubit = context.read<OnboardingCubit>();
    final status = await cubit.readPermissionStatus();
    var notifPermanent = false;
    var locPermanent = false;
    try {
      notifPermanent = await Permission.notification.isPermanentlyDenied;
      final perm = await Geolocator.checkPermission();
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      locPermanent =
          perm == LocationPermission.deniedForever || !serviceOn;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _needNotif = !status.notification;
      _needLocation = !status.foregroundLocation;
      _notifPermanentlyDenied = notifPermanent;
      _locationPermanentlyDenied = locPermanent;
      _loading = false;
    });
  }

  Future<void> _enableNotifications() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final cubit = context.read<OnboardingCubit>();
      if (_notifPermanentlyDenied) {
        await cubit.openSystemSettings();
      } else {
        await cubit.requestNotificationPermission();
      }
      await _sync();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enableLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final cubit = context.read<OnboardingCubit>();
      if (_locationPermanentlyDenied) {
        await cubit.openSystemSettings();
      } else {
        await cubit.requestForegroundLocationPermission();
      }
      await _sync();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || (!_needNotif && !_needLocation)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceLg),
      child: PermissionRequestBanner(
        title: AppStrings.Permissions.bannerTitle.tr,
        subtitle: AppStrings.Permissions.bannerSubtitle.tr,
        showNotifications: _needNotif,
        showLocation: _needLocation,
        notificationsTitle: AppStrings.Permissions.notifications.tr,
        notificationsBody: AppStrings.Permissions.notificationsNeededBody.tr,
        locationTitle: AppStrings.Permissions.location.tr,
        locationBody: AppStrings.Permissions.locationNeededBody.tr,
        enableLabel: AppStrings.Permissions.enable.tr,
        openSettingsLabel: AppStrings.Permissions.openSettings.tr,
        notificationsPermanentlyDenied: _notifPermanentlyDenied,
        locationPermanentlyDenied: _locationPermanentlyDenied,
        busy: _busy,
        onEnableNotifications: _enableNotifications,
        onEnableLocation: _enableLocation,
      ),
    );
  }
}
