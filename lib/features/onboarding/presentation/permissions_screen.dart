import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
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
          icon: Icons.error_outline,
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
          icon: Icons.settings_suggest_outlined,
        );
      }
    } catch (e, st) {
      debugPrint('PermissionsScreen._onContinue error: $e\n$st');
      if (mounted) {
        AppSnack.show(
          context,
          message: '$e',
          state: AppSnackState.error,
          icon: Icons.error_outline,
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
              _PermissionItemCard(
                granted: _status.notification,
                title: AppStrings.Permissions.notifications,
                subtitle: AppStrings.Permissions.notificationsSubtitle,
                icon: Icons.notifications_active_outlined,
                busy: _loading,
                onEnable: () => _wrap(
                  context.read<OnboardingCubit>().requestNotificationPermission,
                ),
              ),
              SizedBox(height: AppSizes.spaceMd),
              _PermissionItemCard(
                granted: _status.foregroundLocation,
                title: AppStrings.Permissions.location,
                subtitle: AppStrings.Permissions.locationSubtitle,
                icon: Icons.location_on_outlined,
                busy: _loading,
                onEnable: () => _wrap(
                  context
                      .read<OnboardingCubit>()
                      .requestForegroundLocationPermission,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: (!_status.allGranted || _loading) ? null : _onContinue,
                child: CustomText(AppStrings.Permissions.continueLabel),
              ),
              SizedBox(height: AppSizes.spaceMd),
              TextButton(
                onPressed: _loading
                    ? null
                    : () =>
                        context.read<OnboardingCubit>().openSystemSettings(),
                child: CustomText(AppStrings.Permissions.openSystemSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItemCard extends StatelessWidget {
  const _PermissionItemCard({
    required this.granted,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.busy,
    required this.onEnable,
  });

  final bool granted;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool busy;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fillColor = granted ? AppColors.success.withValues(alpha: 0.1) : null;

    return Material(
      color: fillColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceBase,
          vertical: AppSizes.spaceMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              granted ? Icons.check_circle_rounded : icon,
              size: AppSizes.iconLg + 4,
              color: granted ? AppColors.success : AppColors.secondColor,
            ),
            SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    style: TextStyle(
                      fontSize: AppSizes.fontTitle,
                      fontWeight: FontWeight.w600,
                      color: granted ? AppColors.success : scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppSizes.spaceXs),
                  CustomText(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppSizes.fontLabel,
                      height: 1.35,
                      color: scheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSizes.spaceSm),
            if (!granted)
              OutlinedButton(
                onPressed: busy ? null : onEnable,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceMd,
                    vertical: AppSizes.spaceSm,
                  ),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
                child: CustomText(AppStrings.Permissions.enable),
              )
            else
              CustomText(
                AppStrings.Permissions.allowed,
                style: TextStyle(
                  fontSize: AppSizes.fontLabel,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
