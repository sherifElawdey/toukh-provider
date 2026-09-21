import 'package:flutter/material.dart';
import 'package:toukh_provider/shared/icons/toukh_icons.dart';
import 'package:toukh_provider/shared/theme/app_colors.dart';
import 'package:toukh_provider/shared/theme/app_sizes.dart';
import 'package:toukh_provider/shared/widgets/app_button.dart';
import 'package:toukh_provider/shared/widgets/custom_text.dart';

/// Professional home banner when notification and/or location access is missing.
///
/// Shows one row per missing permission with an Enable / Open settings CTA.
class PermissionRequestBanner extends StatelessWidget {
  const PermissionRequestBanner({
    super.key,
    this.title,
    this.subtitle,
    this.showNotifications = false,
    this.showLocation = false,
    this.notificationsTitle,
    this.notificationsBody,
    this.locationTitle,
    this.locationBody,
    this.enableLabel = 'Enable',
    this.openSettingsLabel = 'Open settings',
    this.notificationsPermanentlyDenied = false,
    this.locationPermanentlyDenied = false,
    this.busy = false,
    this.onEnableNotifications,
    this.onEnableLocation,
  });

  /// Optional banner headline shown above the permission rows.
  final String? title;
  final String? subtitle;

  final bool showNotifications;
  final bool showLocation;

  final String? notificationsTitle;
  final String? notificationsBody;
  final String? locationTitle;
  final String? locationBody;

  final String enableLabel;
  final String openSettingsLabel;

  final bool notificationsPermanentlyDenied;
  final bool locationPermanentlyDenied;
  final bool busy;

  final VoidCallback? onEnableNotifications;
  final VoidCallback? onEnableLocation;

  bool get _visible => showNotifications || showLocation;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || subtitle != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      ToukhIcons.settings,
                      size: 22,
                      color: AppColors.secondColor,
                    ),
                  ),
                  SizedBox(width: AppSizes.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          CustomText(
                            title!,
                            style: TextStyle(
                              fontSize: AppSizes.fontTitle,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        if (subtitle != null) ...[
                          SizedBox(height: AppSizes.spaceXs),
                          CustomText(
                            subtitle!,
                            style: TextStyle(
                              fontSize: AppSizes.fontCaption,
                              height: 1.35,
                              color: scheme.onSurface.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.spaceMd),
            ],
            if (showNotifications)
              _PermissionRow(
                icon: ToukhIcons.notificationPermission,
                title: notificationsTitle ?? 'Notifications',
                body: notificationsBody ??
                    'Enable notifications to stay updated.',
                actionLabel: notificationsPermanentlyDenied
                    ? openSettingsLabel
                    : enableLabel,
                busy: busy,
                onAction: onEnableNotifications,
              ),
            if (showNotifications && showLocation)
              SizedBox(height: AppSizes.spaceSm),
            if (showLocation)
              _PermissionRow(
                icon: ToukhIcons.location,
                title: locationTitle ?? 'Location',
                body: locationBody ??
                    'Allow location access to use map features.',
                actionLabel: locationPermanentlyDenied
                    ? openSettingsLabel
                    : enableLabel,
                busy: busy,
                onAction: onEnableLocation,
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.busy,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final bool busy;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: AppSizes.iconLg, color: AppColors.secondColor),
        SizedBox(width: AppSizes.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                title,
                style: TextStyle(
                  fontSize: AppSizes.fontBody,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: 2),
              CustomText(
                body,
                style: TextStyle(
                  fontSize: AppSizes.fontCaption,
                  height: 1.35,
                  color: scheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: AppSizes.spaceSm),
        AppOutlinedButton(
          text: actionLabel,
          size: AppButtonSize.small,
          status: busy || onAction == null
              ? AppButtonStatus.disabled
              : AppButtonStatus.enabled,
          onTap: onAction,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMd,
            vertical: AppSizes.spaceSm,
          ),
        ),
      ],
    );
  }
}
