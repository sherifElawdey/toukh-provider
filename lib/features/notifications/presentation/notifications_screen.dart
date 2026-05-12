import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

/// Placeholder until Firestore-backed notifications are wired for providers.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: CustomText(
          AppStrings.Notifications.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.fontTitle,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: AppSizes.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 56,
                color: scheme.onSurface.withValues(alpha: 0.28),
              ),
              SizedBox(height: AppSizes.spaceLg),
              CustomText(
                AppStrings.Notifications.emptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontTitle,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondColor,
                ),
              ),
              SizedBox(height: AppSizes.spaceSm),
              CustomText(
                AppStrings.Notifications.emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontBody,
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: AppSizes.spaceLg),
              CustomText(
                AppStrings.Shell.notificationsComingSoon.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontLabel,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
