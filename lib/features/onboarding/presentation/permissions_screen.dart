import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/shared/shared.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/features/onboarding/presentation/widgets/permission_item_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _notificationPermanentlyDenied = false;
  bool _loading = true;
  bool _busy = false;

  bool get _allGranted => _notificationGranted && _locationGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncStatus();
    }
  }

  Future<bool> _isNotificationPermanentlyDenied() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.denied;
    }
    final status = await Permission.notification.status;
    return status.isPermanentlyDenied || status.isRestricted;
  }

  Future<void> _syncStatus() async {
    final cubit = context.read<OnboardingCubit>();
    final s = await cubit.readPermissionStatus();
    final notifPermanent = await _isNotificationPermanentlyDenied();
    if (!mounted) return;
    setState(() {
      _notificationGranted = s.notification;
      _locationGranted = s.foregroundLocation;
      _notificationPermanentlyDenied =
          !s.notification && notifPermanent;
      _loading = false;
    });
    if (_allGranted) {
      await cubit.continueAfterPermissionsGranted();
    }
  }

  Future<void> _enableNotification() async {
    setState(() => _busy = true);
    try {
      final cubit = context.read<OnboardingCubit>();
      await cubit.requestNotificationPermission();
      // Deny or grant both continue — never trap the user on this screen.
      await cubit.continueAfterNotificationRequest();
    } catch (e, st) {
      debugPrint('PermissionsScreen._enableNotification error: $e\n$st');
      if (mounted) {
        AppSnack.show(
          context,
          message: appFirebaseError(e),
          state: AppSnackState.error,
          icon: PhosphorIconsRegular.bellSlash,
        );
      }
    } finally {
      if (mounted) {
        await _syncStatus();
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _enableLocation() async {
    setState(() => _busy = true);
    try {
      final cubit = context.read<OnboardingCubit>();
      await cubit.requestForegroundLocationPermission();
      await cubit.continueAfterLocationRequest();
    } catch (e, st) {
      debugPrint('PermissionsScreen._enableLocation error: $e\n$st');
      if (mounted) {
        AppSnack.show(
          context,
          message: appFirebaseError(e),
          state: AppSnackState.error,
          icon: PhosphorIconsRegular.gpsSlash,
        );
      }
    } finally {
      if (mounted) {
        await _syncStatus();
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onNotNow() async {
    setState(() => _busy = true);
    try {
      final err = await context.read<OnboardingCubit>().skipPermissionsPrompt();
      if (!mounted) return;
      if (err != null) {
        AppSnack.show(
          context,
          message: err,
          state: AppSnackState.error,
          icon: ToukhIcons.settings,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = _loading || _busy;
    final notifActionLabel = _notificationPermanentlyDenied
        ? AppStrings.Permissions.openSettings.tr
        : AppStrings.Permissions.enable.tr;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: CustomText(AppStrings.Permissions.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.spaceBase),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                AppStrings.Permissions.intro.tr,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
              ),
              SizedBox(height: AppSizes.spaceXl),
              PermissionItemCard(
                granted: _notificationGranted,
                title: AppStrings.Permissions.notifications.tr,
                subtitle: AppStrings.Permissions.notificationsSubtitle.tr,
                icon: ToukhIcons.notificationPermission,
                busy: disabled,
                enableLabel: notifActionLabel,
                onEnable: _enableNotification,
              ),
              SizedBox(height: AppSizes.spaceMd),
              PermissionItemCard(
                granted: _locationGranted,
                title: AppStrings.Permissions.location.tr,
                subtitle: AppStrings.Permissions.locationSubtitle.tr,
                icon: ToukhIcons.location,
                busy: disabled,
                onEnable: _enableLocation,
              ),
              const Spacer(),
              if (!_allGranted) ...[
                if (!_notificationGranted)
                  AppFilledButton(
                    text: notifActionLabel,
                    status: disabled
                        ? AppButtonStatus.disabled
                        : AppButtonStatus.enabled,
                    onTap: _enableNotification,
                  )
                else if (!_locationGranted)
                  AppFilledButton(
                    text: AppStrings.Permissions.allowLocation,
                    status: disabled
                        ? AppButtonStatus.disabled
                        : AppButtonStatus.enabled,
                    onTap: _enableLocation,
                  ),
                SizedBox(height: AppSizes.spaceMd),
                AppTextButton(
                  text: AppStrings.Permissions.notNow,
                  status: disabled
                      ? AppButtonStatus.disabled
                      : AppButtonStatus.enabled,
                  onTap: _onNotNow,
                ),
              ] else
                AppFilledButton(
                  text: AppStrings.Permissions.continueLabel,
                  status: disabled
                      ? AppButtonStatus.disabled
                      : AppButtonStatus.enabled,
                  onTap: () => context
                      .read<OnboardingCubit>()
                      .continueAfterPermissionsGranted(),
                ),
              SizedBox(height: AppSizes.spaceSm),
              AppTextButton(
                text: AppStrings.Permissions.openSystemSettings,
                status: disabled
                    ? AppButtonStatus.disabled
                    : AppButtonStatus.enabled,
                onTap: () =>
                    context.read<OnboardingCubit>().openSystemSettings(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
