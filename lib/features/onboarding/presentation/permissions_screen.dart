import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
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
  PermissionsStatus _status = const PermissionsStatus(
    notification: false,
    foregroundLocation: false,
  );
  bool _loading = true;

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

  Future<void> _syncStatus() async {
    final cubit = context.read<OnboardingCubit>();
    final s = await cubit.readPermissionStatus();
    if (!mounted) return;
    setState(() {
      _status = s;
      _loading = false;
    });
  }

  Future<void> _wrap(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e, st) {
      debugPrint('PermissionsScreen action error: $e\n$st');
      if (mounted) {
        AppSnack.show(
          context,
          message: '$e',
          state: AppSnackState.error,
          icon: ToukhIcons.error,
        );
      }
    } finally {
      if (mounted) await _syncStatus();
    }
  }

  Future<void> _onContinue() async {
    if (!_status.allGranted) return;
    setState(() => _loading = true);
    try {
      final err = await context
          .read<OnboardingCubit>()
          .continueAfterPermissionsGranted();
      if (!mounted) return;
      if (err != null) {
        AppSnack.show(
          context,
          message: err,
          state: AppSnackState.error,
          icon: ToukhIcons.settings,
        );
      }
    } catch (e, st) {
      debugPrint('PermissionsScreen._onContinue error: $e\n$st');
      if (mounted) {
        AppSnack.show(
          context,
          message: '$e',
          state: AppSnackState.error,
          icon: ToukhIcons.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Permissions.title),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSizes.screenPadding.copyWith(
            bottom: AppSizes.spaceBase,
            top: AppSizes.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ToukhServiceLogo(
                  size: 80,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              SizedBox(height: AppSizes.spaceXl),
              CustomText(
                AppStrings.Permissions.intro,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                      color: scheme.onSurface.withValues(alpha: 0.85),
                    ),
              ),
              SizedBox(height: AppSizes.spaceXl),
              PermissionItemCard(
                granted: _status.notification,
                title: AppStrings.Permissions.notifications,
                subtitle: AppStrings.Permissions.notificationsSubtitle,
                icon: ToukhIcons.notificationPermission,
                busy: _loading,
                onEnable: () => _wrap(
                  context.read<OnboardingCubit>().requestNotificationPermission,
                ),
              ),
              SizedBox(height: AppSizes.spaceMd),
              PermissionItemCard(
                granted: _status.foregroundLocation,
                title: AppStrings.Permissions.location,
                subtitle: AppStrings.Permissions.locationSubtitle,
                icon: ToukhIcons.location,
                busy: _loading,
                onEnable: () => _wrap(
                  context
                      .read<OnboardingCubit>()
                      .requestForegroundLocationPermission,
                ),
              ),
              const Spacer(),
              AppFilledButton(
                text: AppStrings.Permissions.continueLabel,
                status: (!_status.allGranted || _loading)
                    ? AppButtonStatus.disabled
                    : AppButtonStatus.enabled,
                onTap: _onContinue,
              ),
              SizedBox(height: AppSizes.spaceMd),
              AppTextButton(
                text: AppStrings.Permissions.openSystemSettings,
                status: _loading
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
