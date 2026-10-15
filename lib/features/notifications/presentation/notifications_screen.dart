import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/core/notifications/notification_labels.dart';
import 'package:toukh_provider/core/notifications/notification_navigation.dart';
import 'package:toukh_provider/features/notifications/cubit/notifications_cubit.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/features/onboarding/presentation/widgets/permission_required_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _permissionChecked = false;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_ensureNotificationPermission());
    });
  }

  Future<void> _ensureNotificationPermission() async {
    final cubit = context.read<OnboardingCubit>();
    final granted = await cubit.isNotificationGranted();
    if (!mounted) return;
    if (granted) {
      setState(() {
        _permissionChecked = true;
        _allowed = true;
      });
      return;
    }

    final permanentlyDenied = await Permission.notification.isPermanentlyDenied;
    if (!mounted) return;
    final enable = await PermissionRequiredSheet.showForNotifications(
      context,
      permanentlyDenied: permanentlyDenied,
    );
    if (!mounted) return;

    if (!enable) {
      context.pop();
      return;
    }

    if (permanentlyDenied) {
      await cubit.openSystemSettings();
      if (mounted) context.pop();
      return;
    }

    await cubit.requestNotificationPermission();
    if (!mounted) return;
    final nowGranted = await cubit.isNotificationGranted();
    if (!mounted) return;
    if (!nowGranted) {
      context.pop();
      return;
    }
    setState(() {
      _permissionChecked = true;
      _allowed = true;
    });
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.Notifications.inboxClearAll.tr),
        content: CustomText(AppStrings.Notifications.inboxClearAllConfirm.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: CustomText(AppStrings.Common.cancel.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: CustomText(AppStrings.Notifications.inboxClearAll.tr),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<NotificationsCubit>().clearAll();
    }
  }

  Future<void> _refresh(BuildContext context) async {
    context.read<NotificationsCubit>().refresh();
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked || !_allowed) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(ToukhIcons.back),
            onPressed: () => context.pop(),
          ),
          title: CustomText(
            AppStrings.Notifications.inboxTitle.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: AppSizes.fontTitle,
            ),
          ),
        ),
        body: const ToukhShimmerList(itemCount: 6, itemHeight: 92),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(
          AppStrings.Notifications.inboxTitle.tr,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.fontTitle,
          ),
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            buildWhen: (prev, next) =>
                prev.items.isNotEmpty != next.items.isNotEmpty,
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: AppStrings.Notifications.inboxClearAll.tr,
                icon: Icon(ToukhIcons.delete),
                onPressed: () => _confirmClearAll(context),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final cubit = context.read<NotificationsCubit>();
          return ToukhNotificationInboxView(
            items: state.newestFirst,
            loading: state.loading,
            showUnreadOnly: state.showUnreadOnly,
            errorMessage: state.errorMessage,
            emptyTitle: AppStrings.Notifications.inboxEmptyTitle.tr,
            emptySubtitle: AppStrings.Notifications.inboxEmptySubtitle.tr,
            onRefresh: () => _refresh(context),
            onToggleUnreadOnly: cubit.toggleUnreadOnly,
            onMarkAllRead: cubit.markAllRead,
            onOpen: (item) async {
              await cubit.markOpened(item);
              await handleProviderNotificationTap(item);
            },
            onDelete: cubit.deleteNotification,
            statusChipLabel: NotificationLabels.statusChipLabel,
            categoryLabel: NotificationLabels.categoryLabel,
          );
        },
      ),
    );
  }
}
