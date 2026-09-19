import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Friendly soft-gate when a feature needs a system permission the user
/// has not granted. Returns `true` if the user chose Enable, `false` for
/// Not now / dismiss.
abstract final class PermissionRequiredSheet {
  const PermissionRequiredSheet._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
    required IconData icon,
    String? enableLabel,
    String? notNowLabel,
    bool permanentlyDenied = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PermissionRequiredSheetBody(
        title: title,
        body: body,
        icon: icon,
        enableLabel: enableLabel ??
            (permanentlyDenied
                ? AppStrings.Permissions.openSettings.tr
                : AppStrings.Permissions.enable.tr),
        notNowLabel: notNowLabel ?? AppStrings.Permissions.notNow.tr,
      ),
    );
    return result ?? false;
  }

  static Future<bool> showForNotifications(
    BuildContext context, {
    bool permanentlyDenied = false,
  }) {
    return show(
      context,
      title: AppStrings.Permissions.notificationsNeededTitle.tr,
      body: AppStrings.Permissions.notificationsNeededBody.tr,
      icon: ToukhIcons.notificationPermission,
      permanentlyDenied: permanentlyDenied,
    );
  }

  static Future<bool> showForLocation(
    BuildContext context, {
    bool permanentlyDenied = false,
  }) {
    return show(
      context,
      title: AppStrings.Permissions.locationNeededTitle.tr,
      body: AppStrings.Permissions.locationNeededBody.tr,
      icon: ToukhIcons.location,
      enableLabel: permanentlyDenied
          ? AppStrings.Permissions.openSettings.tr
          : AppStrings.Permissions.allowLocation.tr,
      permanentlyDenied: permanentlyDenied,
    );
  }
}

class _PermissionRequiredSheetBody extends StatelessWidget {
  const _PermissionRequiredSheetBody({
    required this.title,
    required this.body,
    required this.icon,
    required this.enableLabel,
    required this.notNowLabel,
  });

  final String title;
  final String body;
  final IconData icon;
  final String enableLabel;
  final String notNowLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.spaceXl,
        AppSizes.spaceLg,
        AppSizes.spaceXl,
        AppSizes.spaceXl + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceLg),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondColor.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon,
                size: 44,
                color: AppColors.secondColor,
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceLg),
          CustomText(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontTitle,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: AppSizes.spaceSm),
          CustomText(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontBody,
              height: 1.45,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          SizedBox(height: AppSizes.spaceXl),
          AppFilledButton(
            text: enableLabel,
            onTap: () => Navigator.of(context).pop(true),
          ),
          SizedBox(height: AppSizes.spaceMd),
          AppTextButton(
            text: notNowLabel,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
